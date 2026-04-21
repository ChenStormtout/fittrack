import 'package:sqflite/sqflite.dart';

import '../../core/services/crypto_service.dart';
import '../local/db/app_database.dart';
import '../local/db/table_names.dart';
import '../models/user_model.dart';

class AuthRepository {
  AuthRepository({
    required AppDatabase appDatabase,
    required CryptoService cryptoService,
  })  : _appDatabase = appDatabase,
        _cryptoService = cryptoService;

  final AppDatabase _appDatabase;
  final CryptoService _cryptoService;

  Future<UserModel?> getUserByEmail(String email) async {
    final db = await _appDatabase.database;
    final result = await db.query(
      TableNames.users,
      where: 'email = ?',
      whereArgs: [email.trim().toLowerCase()],
      limit: 1,
    );

    if (result.isEmpty) return null;
    return UserModel.fromMap(result.first);
  }

  Future<bool> register({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();

    final existingUser = await getUserByEmail(normalizedEmail);
    if (existingUser != null) {
      return false;
    }

    final salt = _cryptoService.generateSalt();
    final passwordHash = _cryptoService.hashPassword(
      password: password,
      salt: salt,
    );

    final user = UserModel(
      email: normalizedEmail,
      passwordHash: passwordHash,
      salt: salt,
      createdAt: DateTime.now().toIso8601String(),
    );

    final db = await _appDatabase.database;
    final inserted = await db.insert(
      TableNames.users,
      user.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );

    return inserted > 0;
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final user = await getUserByEmail(normalizedEmail);

    if (user == null) return false;

    final hashedInput = _cryptoService.hashPassword(
      password: password,
      salt: user.salt,
    );

    return hashedInput == user.passwordHash;
  }

  Future<UserModel?> getCurrentUser(String email) async {
    return getUserByEmail(email);
  }

  Future<bool> updateProfile({
    required String email,
    required String fullName,
    required int age,
    required String gender,
    required double heightCm,
    required double weightKg,
    required String goal,
    required String activityLevel,
  }) async {
    final db = await _appDatabase.database;

    final updated = await db.update(
      TableNames.users,
      {
        'full_name': fullName,
        'age': age,
        'gender': gender,
        'height_cm': heightCm,
        'weight_kg': weightKg,
        'goal': goal,
        'activity_level': activityLevel,
      },
      where: 'email = ?',
      whereArgs: [email.trim().toLowerCase()],
    );

    return updated > 0;
  }
}