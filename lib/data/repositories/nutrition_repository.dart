import '../local/db/app_database.dart';
import '../local/db/table_names.dart';
import '../models/nutrition_log_model.dart';
import '../models/water_log_model.dart';

class NutritionRepository {
  NutritionRepository({required AppDatabase appDatabase})
      : _appDatabase = appDatabase;

  final AppDatabase _appDatabase;

  Future<int> insertLog(NutritionLogModel log) async {
    final db = await _appDatabase.database;
    return db.insert(TableNames.nutritionLogs, log.toMap());
  }

  Future<List<NutritionLogModel>> getLogsByDate({
    required String userEmail,
    required String selectedDate,
  }) async {
    final db = await _appDatabase.database;
    final result = await db.query(
      TableNames.nutritionLogs,
      where: 'user_email = ? AND selected_date = ?',
      whereArgs: [userEmail.trim().toLowerCase(), selectedDate],
      orderBy: 'created_at DESC',
    );

    return result.map(NutritionLogModel.fromMap).toList();
  }

  Future<int> updateLog(NutritionLogModel log) async {
    final db = await _appDatabase.database;
    return db.update(
      TableNames.nutritionLogs,
      log.toMap(),
      where: 'id = ?',
      whereArgs: [log.id],
    );
  }

  Future<int> deleteLog(int id) async {
    final db = await _appDatabase.database;
    return db.delete(
      TableNames.nutritionLogs,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> insertWaterLog(WaterLogModel log) async {
    final db = await _appDatabase.database;
    return db.insert(TableNames.waterLogs, log.toMap());
  }

  Future<List<WaterLogModel>> getWaterLogsByDate({
    required String userEmail,
    required String selectedDate,
  }) async {
    final db = await _appDatabase.database;
    final result = await db.query(
      TableNames.waterLogs,
      where: 'user_email = ? AND selected_date = ?',
      whereArgs: [userEmail.trim().toLowerCase(), selectedDate],
      orderBy: 'created_at DESC',
    );

    return result.map(WaterLogModel.fromMap).toList();
  }
}