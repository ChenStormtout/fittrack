import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../data/models/activity_model.dart';
import '../../../data/repositories/activity_repository.dart';

class ActivityResult {
  final String activityType;
  final double distanceKm;
  final int durationSeconds;
  final double caloriesBurned;
  final double elevationGainM;
  final double avgPaceMinPerKm;
  final double maxElevationM;
  final List<LatLng> routeLatLngs;
  final DateTime startTime;
  final DateTime endTime;

  const ActivityResult({
    required this.activityType,
    required this.distanceKm,
    required this.durationSeconds,
    required this.caloriesBurned,
    required this.elevationGainM,
    required this.avgPaceMinPerKm,
    required this.maxElevationM,
    required this.routeLatLngs,
    required this.startTime,
    required this.endTime,
  });
}

class ActivityController extends ChangeNotifier {
  ActivityController({required ActivityRepository activityRepository})
      : _activityRepository = activityRepository;

  final ActivityRepository _activityRepository;

  // ── Max speed filter (m/s) per activity type ──────────────────
  static const _maxSpeedMs = {
    'Walking': 3.5,   // ~12.6 km/h
    'Running': 12.0,  // ~43 km/h
    'Cycling': 20.0,  // ~72 km/h
  };
  static const _minAccuracyM = 25.0; // buang titik akurasi > 25m

  bool _isTracking = false;
  bool _isPaused = false;
  bool _isLoadingHistory = false;

  String _activityType = 'Walking';
  DateTime? _startTime;
  DateTime? _endTime;

  Position? _lastPosition;
  StreamSubscription<Position>? _positionSubscription;
  Timer? _timer;

  int _durationSeconds = 0;
  double _distanceKm = 0;
  double _caloriesBurned = 0;
  double _elevationGainM = 0;
  double _maxElevationM = 0;
  double? _lastAltitude;

  final List<Map<String, double>> _routePoints = [];
  final List<LatLng> _routeLatLngs = [];
  List<ActivityModel> _history = [];
  ActivityResult? _lastResult;

  // Stats untuk debug/info
  int _filteredPoints = 0;

  bool get isTracking => _isTracking;
  bool get isPaused => _isPaused;
  bool get isLoadingHistory => _isLoadingHistory;
  String get activityType => _activityType;
  int get durationSeconds => _durationSeconds;
  double get distanceKm => _distanceKm;
  double get caloriesBurned => _caloriesBurned;
  double get elevationGainM => _elevationGainM;
  double get maxElevationM => _maxElevationM;
  List<ActivityModel> get history => _history;
  List<LatLng> get routeLatLngs => List.unmodifiable(_routeLatLngs);
  ActivityResult? get lastResult => _lastResult;
  int get filteredPoints => _filteredPoints;

  double get paceMinPerKm {
    if (_distanceKm < 0.01) return 0;
    return (_durationSeconds / 60.0) / _distanceKm;
  }

  String get formattedPace {
    final pace = paceMinPerKm;
    if (pace <= 0) return '--:--';
    final min = pace.floor();
    final sec = ((pace - min) * 60).round();
    return "${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}";
  }

  void setActivityType(String value) {
    _activityType = value;
    notifyListeners();
  }

  // ── GPS Filter: tolak titik tidak valid ───────────────────────
  bool _isValidPoint(Position pos) {
    // 1. Filter akurasi buruk
    if (pos.accuracy > _minAccuracyM) {
      _filteredPoints++;
      return false;
    }

    // 2. Filter speed tidak wajar (jika ada titik sebelumnya)
    if (_lastPosition != null) {
      final meters = Geolocator.distanceBetween(
        _lastPosition!.latitude, _lastPosition!.longitude,
        pos.latitude, pos.longitude,
      );
      final timeDiff = pos.timestamp.difference(_lastPosition!.timestamp).inMilliseconds / 1000.0;

      if (timeDiff > 0) {
        final speedMs = meters / timeDiff;
        final maxSpeed = _maxSpeedMs[_activityType] ?? 12.0;

        if (speedMs > maxSpeed) {
          _filteredPoints++;
          return false;
        }
      }

      // 3. Filter titik terlalu dekat (noise GPS diam)
      if (meters < 2.0) {
        return false; // tidak filter, tapi juga tidak tambah jarak
      }
    }

    return true;
  }

  // ── Process valid GPS point ───────────────────────────────────
  void _processPosition(Position position) {
    if (!_isValidPoint(position)) return;

    final point = {'lat': position.latitude, 'lng': position.longitude};
    _routePoints.add(point);
    _routeLatLngs.add(LatLng(position.latitude, position.longitude));

    if (_lastPosition != null) {
      final meters = Geolocator.distanceBetween(
        _lastPosition!.latitude, _lastPosition!.longitude,
        position.latitude, position.longitude,
      );
      // Hanya tambah jarak jika > 2m (filter noise GPS diam)
      if (meters >= 2.0) {
        _distanceKm += meters / 1000.0;
      }
    }

    // Elevation tracking
    final altitude = position.altitude;
    if (_lastAltitude != null && altitude > _lastAltitude! + 0.5) {
      _elevationGainM += altitude - _lastAltitude!;
    }
    _lastAltitude = altitude;
    _maxElevationM = max(_maxElevationM, altitude);

    _lastPosition = position;
    _caloriesBurned = _estimateCalories(
      activityType: _activityType,
      durationSeconds: _durationSeconds,
      distanceKm: _distanceKm,
    );

    notifyListeners();
  }

  // ── Location Settings ─────────────────────────────────────────
  static const _locationSettings = LocationSettings(
    accuracy: LocationAccuracy.bestForNavigation,
    distanceFilter: 3, // update setiap 3 meter
  );

  Future<bool> _requestPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return false;
    }
    return true;
  }

  Future<bool> startTracking() async {
    final allowed = await _requestPermission();
    if (!allowed) return false;

    _isTracking = true;
    _isPaused = false;
    _startTime = DateTime.now();
    _endTime = null;
    _lastPosition = null;
    _durationSeconds = 0;
    _distanceKm = 0;
    _caloriesBurned = 0;
    _elevationGainM = 0;
    _maxElevationM = 0;
    _lastAltitude = null;
    _filteredPoints = 0;
    _routePoints.clear();
    _routeLatLngs.clear();
    _lastResult = null;

    _startTimer();
    _startPositionStream();
    notifyListeners();
    return true;
  }

  void pauseTracking() {
    if (!_isTracking || _isPaused) return;
    _isPaused = true;
    _timer?.cancel();
    _positionSubscription?.cancel();
    _positionSubscription = null;
    notifyListeners();
  }

  Future<void> resumeTracking() async {
    if (!_isTracking || !_isPaused) return;
    _isPaused = false;

    // FIX: reset lastPosition agar tidak "lompat" jarak saat resume
    _lastPosition = null;

    _startTimer();
    _startPositionStream();
    notifyListeners();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _durationSeconds++;
      _caloriesBurned = _estimateCalories(
        activityType: _activityType,
        durationSeconds: _durationSeconds,
        distanceKm: _distanceKm,
      );
      notifyListeners();
    });
  }

  void _startPositionStream() {
    _positionSubscription?.cancel();
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: _locationSettings,
    ).listen(_processPosition);
  }

  Future<bool> stopTracking(String userEmail) async {
    if (!_isTracking || _startTime == null) return false;

    _endTime = DateTime.now();
    _timer?.cancel();
    await _positionSubscription?.cancel();
    _isTracking = false;

    _lastResult = ActivityResult(
      activityType: _activityType,
      distanceKm: _distanceKm,
      durationSeconds: _durationSeconds,
      caloriesBurned: _caloriesBurned,
      elevationGainM: _elevationGainM,
      avgPaceMinPerKm: paceMinPerKm,
      maxElevationM: _maxElevationM,
      routeLatLngs: List.from(_routeLatLngs),
      startTime: _startTime!,
      endTime: _endTime!,
    );

    final activity = ActivityModel(
      userEmail: userEmail.trim().toLowerCase(),
      activityType: _activityType,
      startTime: _startTime!.toIso8601String(),
      endTime: _endTime!.toIso8601String(),
      durationSeconds: _durationSeconds,
      distanceKm: _distanceKm,
      caloriesBurned: _caloriesBurned,
      routeJson: jsonEncode(_routePoints),
      createdAt: DateTime.now().toIso8601String(),
    );

    await _activityRepository.insertActivity(activity);
    await loadHistory(userEmail);

    notifyListeners();
    return true;
  }

  void clearLastResult() {
    _lastResult = null;
    notifyListeners();
  }

  Future<void> loadHistory(String userEmail) async {
    _isLoadingHistory = true;
    notifyListeners();
    _history = await _activityRepository.getActivitiesByUser(userEmail);
    _isLoadingHistory = false;
    notifyListeners();
  }

  double _estimateCalories({
    required String activityType,
    required int durationSeconds,
    required double distanceKm,
  }) {
    final minutes = durationSeconds / 60.0;
    switch (activityType) {
      case 'Running': return minutes * 10.0;
      case 'Cycling': return minutes * 8.0;
      case 'Walking':
      default:        return minutes * 4.5;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _positionSubscription?.cancel();
    super.dispose();
  }
}