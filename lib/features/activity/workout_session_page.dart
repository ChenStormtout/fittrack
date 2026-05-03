import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_colors.dart';
import '../auth/controllers/auth_controller.dart';
import 'controllers/workout_controller.dart';
import 'workout_result_page.dart';

class WorkoutSessionPage extends StatelessWidget {
  const WorkoutSessionPage({super.key});

  String _formatTime(int totalSeconds) {
    final min = totalSeconds ~/ 60;
    final sec = totalSeconds % 60;

    return '${min.toString().padLeft(2, '0')}:'
        '${sec.toString().padLeft(2, '0')}';
  }

  Future<void> _openTutorial(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);

    if (uri == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Link tutorial tidak valid')),
      );
      return;
    }

    try {
      final success = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak bisa membuka tutorial')),
        );
      }
    } catch (_) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal membuka YouTube/browser')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final workoutController = context.watch<WorkoutController>();
    final authController = context.watch<AuthController>();

    final program = workoutController.currentProgram;
    final exercise = workoutController.currentExercise;

    if (program == null || exercise == null) {
      return const Scaffold(
        body: Center(
          child: Text('Workout tidak aktif'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(program.title),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryLight],
              ),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.16),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  program.category,
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 6),
                Text(
                  exercise.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Exercise ${workoutController.currentExerciseIndex + 1}/${workoutController.totalExercises}',
                  style: const TextStyle(color: Colors.white70),
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
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.softCard,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: const Column(
                      children: [
                        Icon(
                          Icons.ondemand_video_rounded,
                          size: 56,
                          color: AppColors.primary,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Buka tutorial video sebelum atau saat latihan',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  Text(
                    exercise.description,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 16),

                  _infoRow(
                    'Set',
                    '${workoutController.currentSet}/${exercise.sets}',
                  ),
                  _infoRow(
                    exercise.isTimed ? 'Durasi Target' : 'Reps Target',
                    exercise.isTimed
                        ? '${exercise.reps} detik'
                        : '${exercise.reps} reps',
                  ),
                  _infoRow(
                    'Rest',
                    '${exercise.restSeconds} detik',
                  ),

                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        _openTutorial(context, exercise.youtubeUrl);
                      },
                      icon: const Icon(Icons.play_circle_outline),
                      label: const Text('Lihat Tutorial'),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  const Text(
                    'Waktu Latihan',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _formatTime(workoutController.elapsedSeconds),
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                  if (workoutController.isResting) ...[
                    const SizedBox(height: 10),
                    Text(
                      'Rest: ${workoutController.restRemaining} detik',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          if (workoutController.isResting)
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: workoutController.skipRest,
                icon: const Icon(Icons.skip_next_rounded),
                label: const Text('Lewati Rest'),
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: workoutController.finishCurrentSet,
                icon: const Icon(Icons.check_rounded),
                label: const Text('Selesai Set Ini'),
              ),
            ),

          const SizedBox(height: 10),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: workoutController.pauseWorkout,
              icon: Icon(
                workoutController.isPaused
                    ? Icons.play_arrow_rounded
                    : Icons.pause_rounded,
              ),
              label: Text(
                workoutController.isPaused ? 'Lanjutkan' : 'Pause',
              ),
            ),
          ),

          const SizedBox(height: 10),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final email = authController.userEmail;

                if (email == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('User belum login'),
                    ),
                  );
                  return;
                }

                final success = await workoutController.completeWorkout(email);

                if (!context.mounted) return;

                if (success) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const WorkoutResultPage(),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.flag_rounded),
              label: const Text('Selesaikan Workout'),
            ),
          ),

          const SizedBox(height: 10),

          TextButton(
            onPressed: () {
              workoutController.cancelWorkout();
              Navigator.pop(context);
            },
            child: const Text(
              'Batalkan Workout',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
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