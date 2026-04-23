import '../local/db/app_database.dart';
import '../local/db/table_names.dart';
import '../models/achievement_model.dart';
import '../models/game_score_model.dart';
import '../models/workout_session_model.dart';

class WorkoutRepository {
  WorkoutRepository({required AppDatabase appDatabase})
      : _appDatabase = appDatabase;

  final AppDatabase _appDatabase;

  Future<int> insertWorkoutSession(WorkoutSessionModel session) async {
    final db = await _appDatabase.database;
    return db.insert(TableNames.workoutSessions, session.toMap());
  }

  Future<List<WorkoutSessionModel>> getWorkoutHistory(String userEmail) async {
    final db = await _appDatabase.database;
    final result = await db.query(
      TableNames.workoutSessions,
      where: 'user_email = ?',
      whereArgs: [userEmail.trim().toLowerCase()],
      orderBy: 'created_at DESC',
    );

    return result.map(WorkoutSessionModel.fromMap).toList();
  }

  Future<int> insertAchievement(AchievementModel achievement) async {
    final db = await _appDatabase.database;
    return db.insert(TableNames.achievements, achievement.toMap());
  }

  Future<List<AchievementModel>> getAchievements(String userEmail) async {
    final db = await _appDatabase.database;
    final result = await db.query(
      TableNames.achievements,
      where: 'user_email = ?',
      whereArgs: [userEmail.trim().toLowerCase()],
      orderBy: 'created_at DESC',
    );

    return result.map(AchievementModel.fromMap).toList();
  }

  Future<int> insertGameScore(GameScoreModel score) async {
    final db = await _appDatabase.database;
    return db.insert(TableNames.gameScores, score.toMap());
  }

  Future<List<GameScoreModel>> getGameScores() async {
    final db = await _appDatabase.database;
    final result = await db.query(
      TableNames.gameScores,
      orderBy: 'score DESC, created_at ASC',
      limit: 20,
    );

    return result.map(GameScoreModel.fromMap).toList();
  }

  Future<List<GameScoreModel>> getGameScoresByUser(String userEmail) async {
    final db = await _appDatabase.database;
    final result = await db.query(
      TableNames.gameScores,
      where: 'user_email = ?',
      whereArgs: [userEmail.trim().toLowerCase()],
      orderBy: 'score DESC, created_at ASC',
    );

    return result.map(GameScoreModel.fromMap).toList();
  }
}