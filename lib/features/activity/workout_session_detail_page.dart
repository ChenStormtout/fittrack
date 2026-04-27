import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../data/models/workout_session_model.dart';

/// Halaman detail hasil sesi latihan gym
class WorkoutSessionDetailPage extends StatelessWidget {
  const WorkoutSessionDetailPage({super.key, required this.session});

  final WorkoutSessionModel session;

  String _formatDuration(int totalSeconds) {
    final h = totalSeconds ~/ 3600;
    final m = (totalSeconds % 3600) ~/ 60;
    final s = totalSeconds % 60;
    if (h > 0) return '${h}j ${m}m ${s}d';
    if (m > 0) return '${m}m ${s}d';
    return '${s}d';
  }

  String _buildAnalysis(WorkoutSessionModel s) {
    final lines = <String>[];
    final isCompleted = s.completed == 1;

    if (isCompleted) {
      lines.add('✅ Sesi latihan selesai dengan sempurna — kerja keras yang luar biasa!');
    } else {
      lines.add('⚡ Sesi latihan selesai sebagian — setiap langkah tetap berarti!');
    }

    final minutes = s.durationSeconds ~/ 60;
    if (minutes >= 45) {
      lines.add('⏱️ $minutes menit latihan intens — konsistensi adalah kunci kemajuan!');
    } else if (minutes >= 20) {
      lines.add('⏱️ $minutes menit latihan efektif. Kualitas lebih penting dari durasi!');
    }

    if (s.totalSets >= 15) {
      lines.add('💪 ${s.totalSets} total set — volume latihan yang sangat tinggi!');
    } else if (s.totalSets >= 8) {
      lines.add('💪 ${s.totalSets} set diselesaikan — volume latihan yang baik!');
    }

    if (s.caloriesBurned > 300) {
      lines.add('🔥 ${s.caloriesBurned.toStringAsFixed(0)} kcal terbakar — pembakaran energi yang maksimal!');
    } else if (s.caloriesBurned > 100) {
      lines.add('🔥 ${s.caloriesBurned.toStringAsFixed(0)} kcal terbakar — kalorimu terbakar dengan baik!');
    }

    switch (s.category.toLowerCase()) {
      case 'strength':
        lines.add('🏋️ Latihan kekuatan membangun otot dan meningkatkan metabolisme basal.');
        break;
      case 'cardio':
        lines.add('❤️ Latihan kardio meningkatkan kesehatan jantung dan stamina!');
        break;
      case 'hiit':
        lines.add('⚡ HIIT adalah salah satu cara paling efisien membakar lemak!');
        break;
      default:
        lines.add('✨ Terus latihan secara konsisten untuk hasil yang optimal!');
    }

    return lines.join('\n\n');
  }

  @override
  Widget build(BuildContext context) {
    final date = DateTime.parse(session.createdAt);
    const actColor = AppColors.primary;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── HERO HEADER ─────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: actColor,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryLight],
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
                        child: const Icon(Icons.fitness_center,
                            color: Colors.white, size: 36),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        session.programName,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
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

                // ── STATUS BADGE ─────────────────────────────────────────
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 8),
                    decoration: BoxDecoration(
                      color: session.completed == 1
                          ? const Color(0xFF4CAF50).withOpacity(0.1)
                          : Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: session.completed == 1
                            ? const Color(0xFF4CAF50)
                            : Colors.orange,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          session.completed == 1
                              ? Icons.check_circle_rounded
                              : Icons.pending_rounded,
                          size: 18,
                          color: session.completed == 1
                              ? const Color(0xFF4CAF50)
                              : Colors.orange,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          session.completed == 1
                              ? 'Latihan Selesai'
                              : 'Selesai Sebagian',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: session.completed == 1
                                ? const Color(0xFF4CAF50)
                                : Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // ── STATS GRID ────────────────────────────────────────────
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.45,
                  children: [
                    _tile('Durasi',
                        _formatDuration(session.durationSeconds), '',
                        Icons.timer_outlined, actColor),
                    _tile('Kalori',
                        session.caloriesBurned.toStringAsFixed(0), 'kcal',
                        Icons.local_fire_department_rounded,
                        const Color(0xFFE91E63)),
                    _tile('Total Set',
                        '${session.totalSets}', 'set',
                        Icons.repeat_rounded, const Color(0xFFFF9800)),
                    _tile('Latihan',
                        '${session.totalExercises}', 'gerakan',
                        Icons.sports_gymnastics_rounded,
                        const Color(0xFF9C27B0)),
                  ],
                ),

                const SizedBox(height: 20),

                // ── INFO CARD ─────────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.softCard,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      _infoRow(Icons.category_rounded, 'Kategori',
                          session.category),
                      const Divider(height: 18),
                      _infoRow(Icons.fitness_center, 'Program',
                          session.programName),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

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
                          child: const Icon(Icons.auto_awesome_rounded,
                              color: actColor, size: 20),
                        ),
                        const SizedBox(width: 10),
                        const Text('Ringkasan Latihan',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800)),
                      ]),
                      const SizedBox(height: 12),
                      Text(
                        _buildAnalysis(session),
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
                      fontSize: 20, fontWeight: FontWeight.w800, color: color)),
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

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(children: [
      Icon(icon, size: 20, color: AppColors.primary),
      const SizedBox(width: 10),
      Text(label,
          style: const TextStyle(
              color: AppColors.textSecondary, fontSize: 13)),
      const Spacer(),
      Text(value,
          style: const TextStyle(
              fontWeight: FontWeight.w700, fontSize: 14)),
    ]);
  }
}
