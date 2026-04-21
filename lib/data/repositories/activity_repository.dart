import '../local/db/app_database.dart';
import '../local/db/table_names.dart';
import '../models/activity_model.dart';

class ActivityRepository {
  ActivityRepository({required AppDatabase appDatabase})
      : _appDatabase = appDatabase;

  final AppDatabase _appDatabase;

  Future<int> insertActivity(ActivityModel activity) async {
    final db = await _appDatabase.database;
    return db.insert(TableNames.activities, activity.toMap());
  }

  Future<List<ActivityModel>> getActivitiesByUser(String email) async {
    final db = await _appDatabase.database;
    final result = await db.query(
      TableNames.activities,
      where: 'user_email = ?',
      whereArgs: [email.trim().toLowerCase()],
      orderBy: 'start_time DESC',
    );

    return result.map(ActivityModel.fromMap).toList();
  }
}