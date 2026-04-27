import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../data/models/activity_model.dart';
import '../../data/models/workout_session_model.dart';
import '../auth/controllers/auth_controller.dart';
import 'activity_detail_page.dart';
import 'controllers/activity_controller.dart';
import 'controllers/workout_controller.dart';
import 'outdoor_tracking_page.dart';
import 'workout_detail_page.dart';
import 'workout_session_detail_page.dart';

class ActivityPage extends StatefulWidget {
  const ActivityPage({super.key});

  @override
  State<ActivityPage> createState() => _ActivityPageState();
}

class _ActivityPageState extends State<ActivityPage> {
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    _loaded = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final email = context.read<AuthController>().userEmail;
      if (email != null) {
        context.read<ActivityController>().loadHistory(email);
        context.read<WorkoutController>().loadHistory(email);
        context.read<WorkoutController>().loadAchievements(email);
      }
    });
  }

  void _startActivity(String type) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OutdoorTrackingPage(activityType: type),
      ),
    );
  }

  // ── Gabungkan dua list dan urutkan terbaru di atas ────────────────────────
  List<_HistoryEntry> _mergedHistory(
    List<ActivityModel> outdoor,
    List<WorkoutSessionModel> gym,
  ) {
    final entries = <_HistoryEntry>[];
    for (final a in outdoor) {
      entries.add(_HistoryEntry.outdoor(a));
    }
    for (final w in gym) {
      entries.add(_HistoryEntry.gym(w));
    }
    entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return entries;
  }

  @override
  Widget build(BuildContext context) {
    final activityCtrl = context.watch<ActivityController>();
    final workoutCtrl = context.watch<WorkoutController>();
    final programs = workoutCtrl.getWorkoutPrograms();

    final merged = _mergedHistory(
      activityCtrl.history,
      workoutCtrl.history,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Aktivitas & Workout')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          // ── OUTDOOR TRACKING HEADER ─────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryLight],
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.18),
                  blurRadius: 22,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Outdoor Tracking',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800),
                ),
                SizedBox(height: 6),
                Text(
                  'Pilih aktivitas untuk mulai tracking GPS dengan peta.',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── 3 ACTIVITY CARDS ─────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _ActivityCard(
                  icon: Icons.directions_walk_rounded,
                  label: 'Walking',
                  color: AppColors.primary,
                  onTap: () => _startActivity('Walking'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActivityCard(
                  icon: Icons.directions_run_rounded,
                  label: 'Running',
                  color: const Color(0xFFE91E63),
                  onTap: () => _startActivity('Running'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActivityCard(
                  icon: Icons.directions_bike_rounded,
                  label: 'Cycling',
                  color: const Color(0xFF2196F3),
                  onTap: () => _startActivity('Cycling'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── WORKOUT PROGRAMS ─────────────────────────────────────────────
          const Text('Workout Programs',
              style:
                  TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          ...programs.map((program) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => WorkoutDetailPage(program: program),
                    ),
                  ),
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.softCard,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Icon(Icons.fitness_center,
                              color: AppColors.primary),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(program.title,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16)),
                              const SizedBox(height: 4),
                              Text(program.subtitle),
                              const SizedBox(height: 6),
                              Text(
                                '${program.category} • ${program.targetArea} • ${program.difficulty}',
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded),
                      ],
                    ),
                  ),
                ),
              )),

          const SizedBox(height: 24),

          // ── ACHIEVEMENT ──────────────────────────────────────────────────
          const Text('Achievement',
              style:
                  TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          if (workoutCtrl.achievements.isEmpty)
            _emptyCard(Icons.emoji_events_outlined, 'Belum ada achievement')
          else
            ...workoutCtrl.achievements.map((item) {
              final date = DateTime.parse(item.createdAt);
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.emoji_events,
                      color: AppColors.primary),
                  title: Text(item.title),
                  subtitle: Text(
                    '${item.description}\n'
                    '${DateFormat('dd MMM yyyy, HH:mm').format(date)}',
                  ),
                  isThreeLine: true,
                ),
              );
            }),

          const SizedBox(height: 24),

          // ── CATATAN LATIHAN (gabungan outdoor + gym) ─────────────────────
          Row(
            children: [
              const Expanded(
                child: Text('Catatan Latihan',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w800)),
              ),
              if (merged.isNotEmpty)
                Text(
                  '${merged.length} sesi',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 13),
                ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Outdoor & gym — ketuk untuk melihat detail',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),

          if (activityCtrl.isLoadingHistory)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              ),
            )
          else if (merged.isEmpty)
            _emptyCard(Icons.history_toggle_off, 'Belum ada catatan latihan')
          else
            ...merged.map((entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: entry.isOutdoor
                      ? _OutdoorHistoryCard(activity: entry.outdoor!)
                      : _GymHistoryCard(session: entry.gym!),
                )),
        ],
      ),
    );
  }

  Widget _emptyCard(IconData icon, String msg) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(icon, size: 36, color: AppColors.textSecondary),
            const SizedBox(height: 8),
            Text(msg),
          ],
        ),
      ),
    );
  }
}

// ── Data wrapper untuk merged list ───────────────────────────────────────────
class _HistoryEntry {
  final bool isOutdoor;
  final ActivityModel? outdoor;
  final WorkoutSessionModel? gym;
  final String createdAt;

  _HistoryEntry.outdoor(ActivityModel a)
      : isOutdoor = true,
        outdoor = a,
        gym = null,
        createdAt = a.createdAt;

  _HistoryEntry.gym(WorkoutSessionModel w)
      : isOutdoor = false,
        outdoor = null,
        gym = w,
        createdAt = w.createdAt;
}

// ── OUTDOOR HISTORY CARD ──────────────────────────────────────────────────────
class _OutdoorHistoryCard extends StatelessWidget {
  const _OutdoorHistoryCard({required this.activity});
  final ActivityModel activity;

  String _dur(int s) {
    final h = s ~/ 3600;
    final m = (s % 3600) ~/ 60;
    if (h > 0) return '${h}j ${m}m';
    return '${m}m';
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

  @override
  Widget build(BuildContext context) {
    final color = _color(activity.activityType);
    final date = DateTime.parse(activity.createdAt);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ActivityDetailPage(activity: activity),
          ),
        ),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.06),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              // Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(_icon(activity.activityType),
                    color: color, size: 24),
              ),
              const SizedBox(width: 14),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(activity.activityType,
                            style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                color: color)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('Outdoor',
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: color)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${activity.distanceKm.toStringAsFixed(2)} km  •  '
                      '${_dur(activity.durationSeconds)}  •  '
                      '${activity.caloriesBurned.toStringAsFixed(0)} kcal',
                      style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      DateFormat('dd MMM yyyy, HH:mm').format(date),
                      style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),

              Icon(Icons.chevron_right_rounded,
                  color: color.withOpacity(0.5)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── GYM HISTORY CARD ──────────────────────────────────────────────────────────
class _GymHistoryCard extends StatelessWidget {
  const _GymHistoryCard({required this.session});
  final WorkoutSessionModel session;

  String _dur(int s) {
    final h = s ~/ 3600;
    final m = (s % 3600) ~/ 60;
    if (h > 0) return '${h}j ${m}m';
    return '${m}m';
  }

  @override
  Widget build(BuildContext context) {
    const color = AppColors.primary;
    final date = DateTime.parse(session.createdAt);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => WorkoutSessionDetailPage(session: session),
          ),
        ),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.06),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              // Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.fitness_center,
                    color: color, size: 22),
              ),
              const SizedBox(width: 14),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(session.programName,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                  color: color)),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('Gym',
                              style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: color)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${session.totalSets} set  •  '
                      '${_dur(session.durationSeconds)}  •  '
                      '${session.caloriesBurned.toStringAsFixed(0)} kcal',
                      style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      DateFormat('dd MMM yyyy, HH:mm').format(date),
                      style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),

              Icon(Icons.chevron_right_rounded,
                  color: color.withOpacity(0.5)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── ACTIVITY CARD WIDGET ─────────────────────────────────────────────────────
class _ActivityCard extends StatelessWidget {
  const _ActivityCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: color.withOpacity(0.22)),
        ),
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(height: 10),
            Text(label,
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: color)),
            const SizedBox(height: 4),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text('Mulai',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}