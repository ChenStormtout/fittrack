import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import 'controllers/activity_controller.dart';

class OutdoorResultPage extends StatelessWidget {
  const OutdoorResultPage({super.key});

  String _formatDuration(int totalSeconds) {
    final h = totalSeconds ~/ 3600;
    final m = (totalSeconds % 3600) ~/ 60;
    final s = totalSeconds % 60;
    return '${h.toString().padLeft(2, '0')}:'
        '${m.toString().padLeft(2, '0')}:'
        '${s.toString().padLeft(2, '0')}';
  }

  String _formatPace(double paceMinPerKm) {
    if (paceMinPerKm <= 0) return '--:--';
    final min = paceMinPerKm.floor();
    final sec = ((paceMinPerKm - min) * 60).round();
    return '${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  String _buildAnalysis(ActivityResult result) {
    final lines = <String>[];

    // Distance feedback
    if (result.distanceKm >= 5) {
      lines.add('🏆 Hebat! Kamu menempuh ${result.distanceKm.toStringAsFixed(2)} km — performa luar biasa!');
    } else if (result.distanceKm >= 2) {
      lines.add('👍 Jarak ${result.distanceKm.toStringAsFixed(2)} km yang solid. Terus tingkatkan!');
    } else if (result.distanceKm > 0) {
      lines.add('🚶 Sesi singkat ${result.distanceKm.toStringAsFixed(2)} km. Konsistensi adalah kunci!');
    } else {
      lines.add('📍 Sesi GPS baru saja dimulai. Coba tracking di area terbuka!');
    }

    // Pace feedback
    if (result.avgPaceMinPerKm > 0) {
      final paceStr = _formatPace(result.avgPaceMinPerKm);
      if (result.activityType == 'Running') {
        if (result.avgPaceMinPerKm < 5) {
          lines.add('⚡ Pace $paceStr /km — kecepatan elite runner!');
        } else if (result.avgPaceMinPerKm < 7) {
          lines.add('🏃 Pace $paceStr /km — pelari yang baik!');
        } else {
          lines.add('🏃 Pace $paceStr /km — tetap konsisten ya!');
        }
      } else if (result.activityType == 'Walking') {
        if (result.avgPaceMinPerKm < 12) {
          lines.add('🚶 Pace $paceStr /km — jalan cepat yang bagus!');
        } else {
          lines.add('🚶 Pace $paceStr /km — santai namun tetap aktif!');
        }
      }
    }

    // Elevation feedback
    if (result.elevationGainM > 50) {
      lines.add('⛰️ Elevasi naik ${result.elevationGainM.toStringAsFixed(0)} m — rute berbukit membakar lebih banyak kalori!');
    } else if (result.elevationGainM > 10) {
      lines.add('📈 Elevasi gain ${result.elevationGainM.toStringAsFixed(0)} m — ada sedikit tanjakan bagus!');
    }

    // Calorie feedback
    if (result.caloriesBurned > 300) {
      lines.add('🔥 ${result.caloriesBurned.toStringAsFixed(0)} kcal terbakar — sesi yang sangat efektif!');
    } else if (result.caloriesBurned > 100) {
      lines.add('🔥 ${result.caloriesBurned.toStringAsFixed(0)} kcal — pembakaran kalori yang baik!');
    }

    // Duration feedback
    final minutes = result.durationSeconds ~/ 60;
    if (minutes >= 30) {
      lines.add('⏱️ Durasi $minutes menit memenuhi rekomendasi WHO untuk aktivitas harian!');
    }

    return lines.join('\n\n');
  }

  IconData _activityIcon(String type) {
    switch (type) {
      case 'Running':
        return Icons.directions_run;
      case 'Cycling':
        return Icons.directions_bike;
      default:
        return Icons.directions_walk;
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

  @override
  Widget build(BuildContext context) {
    final activityController = context.watch<ActivityController>();
    final result = activityController.lastResult;

    if (result == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Hasil Aktivitas')),
        body: const Center(child: Text('Tidak ada data aktivitas')),
      );
    }

    final actColor = _activityColor(result.activityType);
    final analysis = _buildAnalysis(result);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── HERO HEADER ───────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: actColor,
            leading: IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.white),
              onPressed: () {
                activityController.clearLastResult();
                Navigator.popUntil(context, (route) => route.isFirst);
              },
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [actColor, actColor.withOpacity(0.7)],
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
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _activityIcon(result.activityType),
                          color: Colors.white,
                          size: 38,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${result.activityType} Selesai!',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Aktivitas berhasil tersimpan',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── STATS GRID ────────────────────────────────────────────
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.4,
                  children: [
                    _statTile(
                      label: 'Total Jarak',
                      value:
                          '${result.distanceKm.toStringAsFixed(2)}',
                      unit: 'km',
                      icon: Icons.straighten_rounded,
                      color: actColor,
                    ),
                    _statTile(
                      label: 'Moving Time',
                      value: _formatDuration(result.durationSeconds),
                      unit: '',
                      icon: Icons.timer_outlined,
                      color: const Color(0xFF2196F3),
                    ),
                    _statTile(
                      label: 'Avg Pace',
                      value: _formatPace(result.avgPaceMinPerKm),
                      unit: '/km',
                      icon: Icons.speed_rounded,
                      color: const Color(0xFFFF9800),
                    ),
                    _statTile(
                      label: 'Max Elevasi',
                      value: result.maxElevationM.toStringAsFixed(0),
                      unit: 'm',
                      icon: Icons.terrain_rounded,
                      color: const Color(0xFF4CAF50),
                    ),
                    _statTile(
                      label: 'Elevation Gain',
                      value: result.elevationGainM.toStringAsFixed(0),
                      unit: 'm',
                      icon: Icons.trending_up_rounded,
                      color: const Color(0xFF9C27B0),
                    ),
                    _statTile(
                      label: 'Kalori Terbakar',
                      value: result.caloriesBurned.toStringAsFixed(0),
                      unit: 'kcal',
                      icon: Icons.local_fire_department_rounded,
                      color: const Color(0xFFE91E63),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // ── MINI MAP ──────────────────────────────────────────────
                if (result.routeLatLngs.length > 1) ...[
                  const Text(
                    'Rute',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: SizedBox(
                      height: 200,
                      child: FlutterMap(
                        options: MapOptions(
                          initialCenter: result.routeLatLngs[
                              result.routeLatLngs.length ~/ 2],
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
                                points: result.routeLatLngs,
                                color: actColor,
                                strokeWidth: 5,
                                strokeCap: StrokeCap.round,
                              ),
                            ],
                          ),
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: result.routeLatLngs.first,
                                width: 24,
                                height: 24,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF4CAF50),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                              Marker(
                                point: result.routeLatLngs.last,
                                width: 24,
                                height: 24,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEF5350),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // ── ANALISIS AI ───────────────────────────────────────────
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
                      Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: actColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.auto_awesome_rounded,
                              color: actColor,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Analisis Aktivitas',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        analysis,
                        style: const TextStyle(
                          height: 1.5,
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ── ACTION BUTTON ────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      activityController.clearLastResult();
                      Navigator.popUntil(context, (route) => route.isFirst);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: actColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.home_rounded),
                    label: const Text(
                      'Kembali ke Home',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statTile({
    required String label,
    required String value,
    required String unit,
    required IconData icon,
    required Color color,
  }) {
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
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: color.withOpacity(0.8),
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                if (unit.isNotEmpty)
                  TextSpan(
                    text: ' $unit',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: color.withOpacity(0.7),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
