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
    return '${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  Future<void> _openTutorial(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
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
        body: Center(child: Text('Workout tidak aktif')),
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
                  _infoRow('Set', '${workoutController.currentSet}/${exercise.sets}'),
                  _infoRow(
                    exercise.isTimed ? 'Durasi Target' : 'Reps Target',
                    exercise.isTimed ? '${exercise.reps} detik' : '${exercise.reps} reps',
                  ),
                  _infoRow('Rest', '${exercise.restSeconds} detik'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => _openTutorial(exercise.youtubeUrl),
            icon: const Icon(Icons.play_circle_outline),
            label: const Text('Lihat Tutorial'),
          ),
          const SizedBox(height: 12),
          Card(
            color: workoutController.isResting ? AppColors.softAccent : AppColors.softCard,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  Text(
                    workoutController.isResting ? 'Rest Time' : 'Workout Time',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    workoutController.isResting
                        ? '${workoutController.restRemaining}s'
                        : _formatTime(workoutController.elapsedSeconds),
                    style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (!workoutController.isResting)
            ElevatedButton(
              onPressed: workoutController.finishCurrentSet,
              child: Text(exercise.isTimed ? 'Set Selesai' : 'Tandai Set Selesai'),
            ),
          if (workoutController.isResting)
            ElevatedButton(
              onPressed: workoutController.skipRest,
              child: const Text('Lewati Rest'),
            ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: workoutController.pauseWorkout,
            child: Text(
              workoutController.isPaused ? 'Lanjutkan Workout' : 'Pause Manual',
            ),
          ),
          const SizedBox(height: 12),
          if (!workoutController.isWorkoutActive)
            ElevatedButton(
              onPressed: () async {
                if (authController.userEmail == null) return;
                final success = await workoutController.completeWorkout(
                  authController.userEmail!,
                );
                if (!context.mounted) return;
                if (success) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const WorkoutResultPage()),
                  );
                }
              },
              child: const Text('Lihat Hasil Workout'),
            ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              workoutController.cancelWorkout();
              Navigator.pop(context);
            },
            child: const Text('Batalkan Workout'),
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