import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import 'controllers/workout_controller.dart';

class WorkoutResultPage extends StatelessWidget {
  const WorkoutResultPage({super.key});

  String _formatTime(int totalSeconds) {
    final min = totalSeconds ~/ 60;
    final sec = totalSeconds % 60;
    return '${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final workoutController = context.watch<WorkoutController>();
    final result = workoutController.lastCompletedSession;

    if (result == null) {
      return const Scaffold(
        body: Center(child: Text('Tidak ada hasil workout')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Workout Result')),
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
            ),
            child: const Column(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 64),
                SizedBox(height: 12),
                Text(
                  'Workout Selesai',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 24,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Bagus! sesi latihan berhasil diselesaikan',
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
                  _row('Program', result.programName),
                  _row('Kategori', result.category),
                  _row('Exercise', '${result.totalExercises}'),
                  _row('Total Set', '${result.totalSets}'),
                  _row('Durasi', _formatTime(result.durationSeconds)),
                  _row('Kalori', '${result.caloriesBurned.toStringAsFixed(0)} kcal'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              workoutController.clearLastResult();
              Navigator.popUntil(context, (route) => route.isFirst);
            },
            child: const Text('Kembali ke Home'),
          ),
        ],
      ),
    );
  }

  Widget _row(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}