import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../../../data/models/activity_model.dart';
import '../../../data/repositories/activity_repository.dart';

class ActivityController extends ChangeNotifier {
  ActivityController({
    required ActivityRepository activityRepository,
  }) : _activityRepository = activityRepository;

  final ActivityRepository _activityRepository;

  bool _isTracking = false;
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

  final List<Map<String, double>> _routePoints = [];
  List<ActivityModel> _history = [];

  bool get isTracking => _isTracking;
  bool get isLoadingHistory => _isLoadingHistory;
  String get activityType => _activityType;
  int get durationSeconds => _durationSeconds;
  double get distanceKm => _distanceKm;
  double get caloriesBurned => _caloriesBurned;
  List<ActivityModel> get history => _history;

  void setActivityType(String value) {
    _activityType = value;
    notifyListeners();
  }

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
    _startTime = DateTime.now();
    _endTime = null;
    _lastPosition = null;
    _durationSeconds = 0;
    _distanceKm = 0;
    _caloriesBurned = 0;
    _routePoints.clear();

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

    _positionSubscription?.cancel();
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 5,
      ),
    ).listen((position) {
      final currentPoint = {
        'lat': position.latitude,
        'lng': position.longitude,
      };
      _routePoints.add(currentPoint);

      if (_lastPosition != null) {
        final meters = Geolocator.distanceBetween(
          _lastPosition!.latitude,
          _lastPosition!.longitude,
          position.latitude,
          position.longitude,
        );
        _distanceKm += meters / 1000.0;
      }

      _lastPosition = position;
      _caloriesBurned = _estimateCalories(
        activityType: _activityType,
        durationSeconds: _durationSeconds,
        distanceKm: _distanceKm,
      );

      notifyListeners();
    });

    notifyListeners();
    return true;
  }

  Future<bool> stopTracking(String userEmail) async {
    if (!_isTracking || _startTime == null) return false;

    _endTime = DateTime.now();

    _timer?.cancel();
    await _positionSubscription?.cancel();

    _isTracking = false;

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
      case 'Running':
        return minutes * 10.0;
      case 'Cycling':
        return minutes * 8.0;
      case 'Walking':
      default:
        return minutes * 4.5;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _positionSubscription?.cancel();
    super.dispose();
  }
}