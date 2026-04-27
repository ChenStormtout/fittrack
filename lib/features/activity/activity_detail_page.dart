import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../../core/constants/app_colors.dart';
import '../../data/models/activity_model.dart';

/// Halaman detail hasil aktivitas outdoor (Walking / Running / Cycling)
class ActivityDetailPage extends StatelessWidget {
  const ActivityDetailPage({super.key, required this.activity});

  final ActivityModel activity;

  // ── helpers ──────────────────────────────────────────────────────────────
  String _formatDuration(int totalSeconds) {
    final h = totalSeconds ~/ 3600;
    final m = (totalSeconds % 3600) ~/ 60;
    final s = totalSeconds % 60;
    if (h > 0) return '${h}j ${m}m ${s}d';
    if (m > 0) return '${m}m ${s}d';
    return '${s}d';
  }

  String _pace(int durationSeconds, double distanceKm) {
    if (distanceKm <= 0) return '--:--';
    final paceMin = (durationSeconds / 60) / distanceKm;
    final min = paceMin.floor();
    final sec = ((paceMin - min) * 60).round();
    return '${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  List<LatLng> _parseRoute(String routeJson) {
    try {
      final list = jsonDecode(routeJson) as List<dynamic>;
      return list.map((p) {
        final lat = (p['lat'] as num).toDouble();
        final lng = (p['lng'] as num).toDouble();
        return LatLng(lat, lng);
      }).toList();
    } catch (_) {
      return [];
    }
  }

  IconData _icon(String type) {
    switch (type) {
      case 'Running':
        return Icons.directions_run;
      case 'Cycling':
        return Icons.directions_bike;
      default:
        return Icons.directions_walk;
    }
  }

  Color _color(String type) {
    switch (type) {
      case 'Running':
        return const Color(0xFFE91E63);
      case 'Cycling':
        return const Color(0xFF2196F3);
      default:
        return AppColors.primary;
    }
  }

  String _buildAnalysis(ActivityModel act) {
    final lines = <String>[];
    if (act.distanceKm >= 5) {
      lines.add('🏆 Luar biasa! ${act.distanceKm.toStringAsFixed(2)} km adalah pencapaian hebat!');
    } else if (act.distanceKm >= 2) {
      lines.add('👍 Jarak ${act.distanceKm.toStringAsFixed(2)} km — terus konsisten!');
    } else {
      lines.add('🚶 Sesi ${act.distanceKm.toStringAsFixed(2)} km. Konsistensi lebih penting dari jarak!');
    }
    final minutes = act.durationSeconds ~/ 60;
    if (minutes >= 30) {
      lines.add('⏱️ Durasi $minutes menit memenuhi rekomendasi aktivitas harian WHO!');
    }
    if (act.caloriesBurned > 200) {
      lines.add('🔥 ${act.caloriesBurned.toStringAsFixed(0)} kcal terbakar — pembakaran kalori yang sangat efektif!');
    } else if (act.caloriesBurned > 50) {
      lines.add('🔥 ${act.caloriesBurned.toStringAsFixed(0)} kcal terbakar — bagus!');
    }
    return lines.join('\n\n');
  }

  @override
  Widget build(BuildContext context) {
    final actColor = _color(activity.activityType);
    final routePoints = _parseRoute(activity.routeJson);
    final date = DateTime.parse(activity.createdAt);
    final pace = _pace(activity.durationSeconds, activity.distanceKm);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── HERO HEADER ────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: actColor,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [actColor, actColor.withOpacity(0.75)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      Container(
                        width: 68,
                        height: 68,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(_icon(activity.activityType),
                            color: Colors.white, size: 36),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        activity.activityType,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        DateFormat('dd MMMM yyyy • HH:mm').format(date),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.85),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate([

                // ── STATS GRID ────────────────────────────────────────────
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.45,
                  children: [
                    _tile('Total Jarak',
                        activity.distanceKm.toStringAsFixed(2), 'km',
                        Icons.straighten_rounded, actColor),
                    _tile('Durasi',
                        _formatDuration(activity.durationSeconds), '',
                        Icons.timer_outlined, const Color(0xFF2196F3)),
                    _tile('Avg Pace', pace, '/km',
                        Icons.speed_rounded, const Color(0xFFFF9800)),
                    _tile('Kalori',
                        activity.caloriesBurned.toStringAsFixed(0), 'kcal',
                        Icons.local_fire_department_rounded,
                        const Color(0xFFE91E63)),
                  ],
                ),

                const SizedBox(height: 20),

                // ── MINI MAP ──────────────────────────────────────────────
                if (routePoints.length > 1) ...[
                  const Text('Rute',
                      style: TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: SizedBox(
                      height: 200,
                      child: FlutterMap(
                        options: MapOptions(
                          initialCenter:
                              routePoints[routePoints.length ~/ 2],
                          initialZoom: 15,
                          interactionOptions: const InteractionOptions(
                            flags: InteractiveFlag.none,
                          ),
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.fitrack.app',
                          ),
                          PolylineLayer(
                            polylines: [
                              Polyline(
                                points: routePoints,
                                color: actColor,
                                strokeWidth: 5,
                                strokeCap: StrokeCap.round,
                              ),
                            ],
                          ),
                          MarkerLayer(markers: [
                            _dot(routePoints.first,
                                const Color(0xFF4CAF50)),
                            _dot(routePoints.last,
                                const Color(0xFFEF5350)),
                          ]),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // ── ANALISIS ──────────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: actColor.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: actColor.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: actColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.auto_awesome_rounded,
                              color: actColor, size: 20),
                        ),
                        const SizedBox(width: 10),
                        const Text('Ringkasan Aktivitas',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800)),
                      ]),
                      const SizedBox(height: 12),
                      Text(
                        _buildAnalysis(activity),
                        style: const TextStyle(
                            height: 1.5,
                            fontSize: 14,
                            color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tile(String label, String value, String unit,
      IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [
            Icon(icon, color: color, size: 15),
            const SizedBox(width: 5),
            Expanded(
              child: Text(label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 11,
                      color: color.withOpacity(0.8),
                      fontWeight: FontWeight.w500)),
            ),
          ]),
          RichText(
            text: TextSpan(children: [
              TextSpan(
                  text: value,
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: color)),
              if (unit.isNotEmpty)
                TextSpan(
                    text: ' $unit',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: color.withOpacity(0.7))),
            ]),
          ),
        ],
      ),
    );
  }

  Marker _dot(LatLng point, Color color) {
    return Marker(
      point: point,
      width: 22,
      height: 22,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2.5),
        ),
      ),
    );
  }
}
