import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../../core/constants/app_colors.dart';
import '../../data/models/activity_model.dart';

class ActivityDetailPage extends StatefulWidget {
  const ActivityDetailPage({super.key, required this.activity});

  final ActivityModel activity;

  @override
  State<ActivityDetailPage> createState() => _ActivityDetailPageState();
}

class _ActivityDetailPageState extends State<ActivityDetailPage> {
  static const _fallbackCenter = LatLng(-6.2088, 106.8456);

  final MapController _mapController = MapController();
  late final List<LatLng> _routePoints;
  late final DateTime _date;

  ActivityModel get _activity => widget.activity;

  @override
  void initState() {
    super.initState();
    _routePoints = _parseRoute(_activity.routeJson);
    _date = DateTime.tryParse(_activity.createdAt) ?? DateTime.now();
  }

  List<LatLng> _parseRoute(String routeJson) {
    try {
      final list = jsonDecode(routeJson) as List<dynamic>;
      return list
          .whereType<Map>()
          .map((point) {
            final lat = point['lat'];
            final lng = point['lng'];
            if (lat is! num || lng is! num) return null;
            return LatLng(lat.toDouble(), lng.toDouble());
          })
          .whereType<LatLng>()
          .toList();
    } catch (_) {
      return [];
    }
  }

  String _formatDuration(int totalSeconds) {
    final h = totalSeconds ~/ 3600;
    final m = (totalSeconds % 3600) ~/ 60;
    final s = totalSeconds % 60;
    return '${h.toString().padLeft(2, '0')}:'
        '${m.toString().padLeft(2, '0')}:'
        '${s.toString().padLeft(2, '0')}';
  }

  String _formatShortDuration(int totalSeconds) {
    final h = totalSeconds ~/ 3600;
    final m = (totalSeconds % 3600) ~/ 60;
    if (h > 0) return '${h}j ${m}m';
    if (m > 0) return '${m}m';
    return '${totalSeconds}s';
  }

  String _formatPace(int durationSeconds, double distanceKm) {
    if (distanceKm <= 0.01 || durationSeconds <= 0) return '--:--';
    final paceSeconds = (durationSeconds / distanceKm).round();
    final min = paceSeconds ~/ 60;
    final sec = paceSeconds % 60;
    return '${min.toString().padLeft(2, '0')}:'
        '${sec.toString().padLeft(2, '0')}';
  }

  IconData _activityIcon(String type) {
    switch (type) {
      case 'Running':
        return Icons.directions_run_rounded;
      case 'Cycling':
        return Icons.directions_bike_rounded;
      default:
        return Icons.directions_walk_rounded;
    }
  }

  Color _activityColor(String type) {
    switch (type) {
      case 'Running':
        return const Color(0xFFE91E63);
      case 'Cycling':
        return const Color(0xFF2196F3);
      default:
        return AppColors.primary;
    }
  }

  LatLng _initialCenter() {
    if (_routePoints.length > 1) {
      return LatLngBounds.fromPoints(_routePoints).center;
    }
    if (_routePoints.isNotEmpty) return _routePoints.first;
    return _fallbackCenter;
  }

  void _fitRoute() {
    if (_routePoints.length > 1) {
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: LatLngBounds.fromPoints(_routePoints),
          padding: const EdgeInsets.fromLTRB(48, 120, 48, 280),
          maxZoom: 17,
        ),
      );
      return;
    }

    if (_routePoints.isNotEmpty) {
      _mapController.move(_routePoints.first, 17);
    }
  }

  List<String> _buildAnalysis(ActivityModel activity) {
    final pace = _formatPace(activity.durationSeconds, activity.distanceKm);
    final minutes = activity.durationSeconds ~/ 60;
    final lines = <String>[];

    if (activity.distanceKm >= 5) {
      lines.add(
        'Jarak ${activity.distanceKm.toStringAsFixed(2)} km menunjukkan sesi yang kuat. Pertahankan rute ini sebagai patokan progres.',
      );
    } else if (activity.distanceKm >= 2) {
      lines.add(
        'Jarak ${activity.distanceKm.toStringAsFixed(2)} km sudah solid. Kamu bisa menaikkan jarak sedikit demi sedikit di sesi berikutnya.',
      );
    } else if (activity.distanceKm > 0) {
      lines.add(
        'Sesi ${activity.distanceKm.toStringAsFixed(2)} km ini tetap tercatat baik. Fokus dulu pada konsistensi dan kualitas tracking.',
      );
    } else {
      lines.add(
        'Jarak belum terbaca dari GPS. Coba mulai aktivitas di area terbuka agar rute berikutnya lebih lengkap.',
      );
    }

    if (pace != '--:--') {
      lines.add(
        'Rata-rata pace kamu $pace /km dengan moving time ${_formatShortDuration(activity.durationSeconds)}.',
      );
    }

    if (minutes >= 30) {
      lines.add(
        'Durasi $minutes menit sudah masuk zona latihan harian yang bagus untuk kebugaran.',
      );
    } else if (minutes > 0) {
      lines.add(
        'Durasi $minutes menit cocok untuk sesi ringan. Tambahkan waktu saat badan sudah terasa siap.',
      );
    }

    if (activity.caloriesBurned > 0) {
      lines.add(
        'Estimasi kalori terbakar ${activity.caloriesBurned.toStringAsFixed(0)} kcal.',
      );
    }

    return lines;
  }

  @override
  Widget build(BuildContext context) {
    final activity = _activity;
    final actColor = _activityColor(activity.activityType);
    final pace = _formatPace(activity.durationSeconds, activity.distanceKm);
    final hasRoute = _routePoints.length > 1;

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _initialCenter(),
              initialZoom: _routePoints.isEmpty ? 13 : 16,
              initialCameraFit: hasRoute
                  ? CameraFit.bounds(
                      bounds: LatLngBounds.fromPoints(_routePoints),
                      padding: const EdgeInsets.fromLTRB(48, 116, 48, 280),
                      maxZoom: 17,
                    )
                  : null,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.fitrack.app',
              ),
              if (hasRoute)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      color: Colors.black.withValues(alpha: 0.18),
                      strokeWidth: 9,
                      strokeCap: StrokeCap.round,
                    ),
                    Polyline(
                      points: _routePoints,
                      color: actColor,
                      strokeWidth: 5.5,
                      strokeCap: StrokeCap.round,
                    ),
                  ],
                ),
              if (_routePoints.isNotEmpty)
                MarkerLayer(
                  markers: [
                    _routeDot(_routePoints.first, const Color(0xFF4CAF50)),
                    if (hasRoute)
                      _routeDot(_routePoints.last, const Color(0xFFEF5350)),
                  ],
                ),
            ],
          ),
          if (_routePoints.isEmpty) _NoRouteBanner(color: actColor),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Row(
                  children: [
                    _MapButton(
                      icon: Icons.arrow_back_rounded,
                      onTap: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: actColor.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _activityIcon(activity.activityType),
                                size: 17,
                                color: actColor,
                              ),
                            ),
                            const SizedBox(width: 9),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    activity.activityType,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: actColor,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Text(
                                    DateFormat(
                                      'dd MMM yyyy, HH:mm',
                                    ).format(_date),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _MapButton(
                      icon: Icons.center_focus_strong_rounded,
                      onTap: _fitRoute,
                      color: actColor,
                    ),
                  ],
                ),
              ),
            ),
          ),
          DraggableScrollableSheet(
            initialChildSize: 0.34,
            minChildSize: 0.22,
            maxChildSize: 0.78,
            snap: true,
            snapSizes: const [0.34, 0.78],
            builder: (context, scrollController) {
              final bottomPadding = MediaQuery.of(context).padding.bottom;
              return DecoratedBox(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 24,
                      offset: Offset(0, -4),
                    ),
                  ],
                ),
                child: ListView(
                  controller: scrollController,
                  padding: EdgeInsets.fromLTRB(20, 12, 20, bottomPadding + 24),
                  children: [
                    Center(
                      child: Container(
                        width: 42,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Hasil Tracking',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                hasRoute
                                    ? '${_routePoints.length} titik GPS tersimpan'
                                    : 'Rute GPS belum lengkap',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: actColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            pace == '--:--' ? 'Pace --' : '$pace /km',
                            style: TextStyle(
                              color: actColor,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _MetricCard(
                            icon: Icons.straighten_rounded,
                            label: 'Jarak',
                            value: activity.distanceKm.toStringAsFixed(2),
                            unit: 'km',
                            color: actColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _MetricCard(
                            icon: Icons.timer_outlined,
                            label: 'Moving Time',
                            value: _formatDuration(activity.durationSeconds),
                            unit: '',
                            color: const Color(0xFF2196F3),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _MetricCard(
                            icon: Icons.speed_rounded,
                            label: 'Avg Pace',
                            value: pace,
                            unit: '/km',
                            color: const Color(0xFFFF9800),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _MetricCard(
                            icon: Icons.local_fire_department_rounded,
                            label: 'Kalori',
                            value: activity.caloriesBurned.toStringAsFixed(0),
                            unit: 'kcal',
                            color: const Color(0xFFE91E63),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _AnalysisPanel(
                      color: actColor,
                      lines: _buildAnalysis(activity),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Marker _routeDot(LatLng point, Color color) {
    return Marker(
      point: point,
      width: 24,
      height: 24,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
            ),
          ],
        ),
      ),
    );
  }
}

class _MapButton extends StatelessWidget {
  const _MapButton({
    required this.icon,
    required this.onTap,
    this.color = AppColors.textPrimary,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: color, size: 21),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final String unit;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 96),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color.withValues(alpha: 0.75),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: value,
                    style: TextStyle(
                      color: color,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (unit.isNotEmpty)
                    TextSpan(
                      text: ' $unit',
                      style: TextStyle(
                        color: color.withValues(alpha: 0.72),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalysisPanel extends StatelessWidget {
  const _AnalysisPanel({required this.color, required this.lines});

  final Color color;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.insights_rounded, color: color, size: 20),
              ),
              const SizedBox(width: 10),
              const Text(
                'Analisis Aktivitas',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...lines.map(
            (line) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    margin: const EdgeInsets.only(top: 7),
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      line,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoRouteBanner extends StatelessWidget {
  const _NoRouteBanner({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 76,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(Icons.location_off_rounded, color: color, size: 18),
            const SizedBox(width: 9),
            const Expanded(
              child: Text(
                'Rute GPS tidak tersedia untuk sesi ini.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
