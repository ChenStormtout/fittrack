import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_colors.dart';
import 'controllers/workout_controller.dart';
import 'workout_session_page.dart';

class WorkoutDetailPage extends StatelessWidget {
  const WorkoutDetailPage({
    super.key,
    required this.program,
  });

  final WorkoutProgram program;

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
    final workoutController = context.read<WorkoutController>();

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
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.16),
                  blurRadius: 22,
                  offset: const Offset(0, 12),
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
                  program.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 24,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  program.subtitle,
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
                  _infoRow('Target Area', program.targetArea),
                  _infoRow('Difficulty', program.difficulty),
                  _infoRow(
                    'Estimated Duration',
                    '${program.estimatedMinutes} menit',
                  ),
                  _infoRow(
                    'Total Exercise',
                    '${program.exercises.length}',
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 18),
          const Text(
            'Daftar Exercise',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),

          ...program.exercises.asMap().entries.map((entry) {
            final index = entry.key;
            final exercise = entry.value;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: AppColors.softCard,
                            child: Text('${index + 1}'),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              exercise.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      Text(
                        exercise.description,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          height: 1.35,
                        ),
                      ),

                      const SizedBox(height: 12),

                      _miniInfo(
                        exercise.isTimed ? 'Durasi' : 'Reps',
                        exercise.isTimed
                            ? '${exercise.reps} detik'
                            : '${exercise.reps} reps',
                      ),
                      _miniInfo('Set', '${exercise.sets}'),
                      _miniInfo('Rest', '${exercise.restSeconds} detik'),

                      const SizedBox(height: 12),

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
            );
          }),

          const SizedBox(height: 8),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                workoutController.startWorkout(program);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const WorkoutSessionPage(),
                  ),
                );
              },
              child: const Text('Mulai Workout'),
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

  Widget _miniInfo(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}