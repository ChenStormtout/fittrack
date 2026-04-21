class WorkoutSessionModel {
  final int? id;
  final String userEmail;
  final String category;
  final String programName;
  final int totalExercises;
  final int totalSets;
  final int durationSeconds;
  final double caloriesBurned;
  final int completed;
  final String createdAt;

  WorkoutSessionModel({
    this.id,
    required this.userEmail,
    required this.category,
    required this.programName,
    required this.totalExercises,
    required this.totalSets,
    required this.durationSeconds,
    required this.caloriesBurned,
    required this.completed,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_email': userEmail,
      'category': category,
      'program_name': programName,
      'total_exercises': totalExercises,
      'total_sets': totalSets,
      'duration_seconds': durationSeconds,
      'calories_burned': caloriesBurned,
      'completed': completed,
      'created_at': createdAt,
    };
  }

  factory WorkoutSessionModel.fromMap(Map<String, dynamic> map) {
    return WorkoutSessionModel(
      id: map['id'] as int?,
      userEmail: map['user_email'] as String,
      category: map['category'] as String,
      programName: map['program_name'] as String,
      totalExercises: map['total_exercises'] as int,
      totalSets: map['total_sets'] as int,
      durationSeconds: map['duration_seconds'] as int,
      caloriesBurned: (map['calories_burned'] as num).toDouble(),
      completed: map['completed'] as int,
      createdAt: map['created_at'] as String,
    );
  }
}