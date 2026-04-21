import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../auth/controllers/auth_controller.dart';
import 'controllers/activity_controller.dart';
import 'controllers/workout_controller.dart';
import 'workout_detail_page.dart';

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
      final userEmail = context.read<AuthController>().userEmail;
      if (userEmail != null) {
        context.read<ActivityController>().loadHistory(userEmail);
        context.read<WorkoutController>().loadHistory(userEmail);
        context.read<WorkoutController>().loadAchievements(userEmail);
      }
    });
  }

  String _formatDuration(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();
    final activityController = context.watch<ActivityController>();
    final workoutController = context.watch<WorkoutController>();
    final programs = workoutController.getWorkoutPrograms();

    return Scaffold(
      appBar: AppBar(title: const Text('Aktivitas & Workout')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryLight],
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.16),
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
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Walking, running, dan cycling berbasis GPS.',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    value: activityController.activityType,
                    decoration: const InputDecoration(
                      labelText: 'Tipe Aktivitas Outdoor',
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Walking', child: Text('Walking')),
                      DropdownMenuItem(value: 'Running', child: Text('Running')),
                      DropdownMenuItem(value: 'Cycling', child: Text('Cycling')),
                    ],
                    onChanged: activityController.isTracking
                        ? null
                        : (value) {
                            if (value != null) {
                              activityController.setActivityType(value);
                            }
                          },
                  ),
                  const SizedBox(height: 14),
                  _box('Durasi', _formatDuration(activityController.durationSeconds)),
                  const SizedBox(height: 10),
                  _box('Jarak', '${activityController.distanceKm.toStringAsFixed(2)} km'),
                  const SizedBox(height: 10),
                  _box('Kalori', '${activityController.caloriesBurned.toStringAsFixed(0)} kcal'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () async {
                      if (activityController.isTracking) {
                        if (authController.userEmail != null) {
                          await activityController.stopTracking(authController.userEmail!);
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Aktivitas disimpan')),
                          );
                        }
                      } else {
                        final started = await activityController.startTracking();
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              started
                                  ? 'Tracking dimulai'
                                  : 'GPS belum aktif / izin lokasi ditolak',
                            ),
                          ),
                        );
                      }
                    },
                    child: Text(
                      activityController.isTracking ? 'Stop Aktivitas' : 'Start Aktivitas',
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            'Workout Programs',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          ...programs.map((program) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => WorkoutDetailPage(program: program),
                    ),
                  );
                },
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
                        child: const Icon(Icons.fitness_center, color: AppColors.primary),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              program.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(program.subtitle),
                            const SizedBox(height: 6),
                            Text(
                              '${program.category} • ${program.targetArea} • ${program.difficulty}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 22),
          const Text(
            'Achievement',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          if (workoutController.achievements.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: const [
                    Icon(Icons.emoji_events_outlined, size: 36, color: AppColors.textSecondary),
                    SizedBox(height: 8),
                    Text('Belum ada achievement'),
                  ],
                ),
              ),
            )
          else
            ...workoutController.achievements.map((item) {
              final date = DateTime.parse(item.createdAt);
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.emoji_events, color: AppColors.primary),
                  title: Text(item.title),
                  subtitle: Text(
                    '${item.description}\n${DateFormat('dd MMM yyyy, HH:mm').format(date)}',
                  ),
                  isThreeLine: true,
                ),
              );
            }),
          const SizedBox(height: 22),
          const Text(
            'Riwayat Workout',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          if (workoutController.history.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: const [
                    Icon(Icons.history_toggle_off, size: 36, color: AppColors.textSecondary),
                    SizedBox(height: 8),
                    Text('Belum ada riwayat workout'),
                  ],
                ),
              ),
            )
          else
            ...workoutController.history.map((item) {
              final date = DateTime.parse(item.createdAt);
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.task_alt, color: AppColors.primary),
                  title: Text(item.programName),
                  subtitle: Text(
                    '${item.category} • ${item.totalSets} set • ${item.caloriesBurned.toStringAsFixed(0)} kcal\n'
                    '${DateFormat('dd MMM yyyy, HH:mm').format(date)}',
                  ),
                  isThreeLine: true,
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _box(String title, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.softCard,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}