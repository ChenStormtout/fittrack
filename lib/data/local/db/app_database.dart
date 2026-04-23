import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'table_names.dart';

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'fitlife.db');

    return openDatabase(
      path,
      version: 7,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE ${TableNames.users} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        email TEXT NOT NULL UNIQUE,
        password_hash TEXT NOT NULL,
        salt TEXT NOT NULL,
        created_at TEXT NOT NULL,
        full_name TEXT,
        age INTEGER,
        gender TEXT,
        height_cm REAL,
        weight_kg REAL,
        goal TEXT,
        calisthenics_level TEXT,
        activity_level TEXT,
        profile_image TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE ${TableNames.activities} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_email TEXT NOT NULL,
        activity_type TEXT NOT NULL,
        start_time TEXT NOT NULL,
        end_time TEXT NOT NULL,
        duration_seconds INTEGER NOT NULL,
        distance_km REAL NOT NULL,
        calories_burned REAL NOT NULL,
        route_json TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE ${TableNames.nutritionLogs} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_email TEXT NOT NULL,
        food_name TEXT NOT NULL,
        calories REAL NOT NULL,
        protein REAL NOT NULL,
        carbs REAL NOT NULL,
        fat REAL NOT NULL,
        meal_type TEXT NOT NULL,
        grams REAL NOT NULL,
        selected_date TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE ${TableNames.waterLogs} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_email TEXT NOT NULL,
        amount_ml INTEGER NOT NULL,
        selected_date TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE ${TableNames.workoutSessions} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_email TEXT NOT NULL,
        category TEXT NOT NULL,
        program_name TEXT NOT NULL,
        total_exercises INTEGER NOT NULL,
        total_sets INTEGER NOT NULL,
        duration_seconds INTEGER NOT NULL,
        calories_burned REAL NOT NULL,
        completed INTEGER NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE ${TableNames.achievements} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_email TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE ${TableNames.gameScores} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_email TEXT NOT NULL,
        player_name TEXT NOT NULL,
        game_name TEXT NOT NULL,
        score INTEGER NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE ${TableNames.users} ADD COLUMN full_name TEXT');
      await db.execute('ALTER TABLE ${TableNames.users} ADD COLUMN age INTEGER');
      await db.execute('ALTER TABLE ${TableNames.users} ADD COLUMN gender TEXT');
      await db.execute('ALTER TABLE ${TableNames.users} ADD COLUMN height_cm REAL');
      await db.execute('ALTER TABLE ${TableNames.users} ADD COLUMN weight_kg REAL');
      await db.execute('ALTER TABLE ${TableNames.users} ADD COLUMN goal TEXT');
      await db.execute('ALTER TABLE ${TableNames.users} ADD COLUMN calisthenics_level TEXT');
      await db.execute('ALTER TABLE ${TableNames.users} ADD COLUMN activity_level TEXT');
      await db.execute('ALTER TABLE ${TableNames.users} ADD COLUMN profile_image TEXT');
    }

    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE ${TableNames.activities} (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_email TEXT NOT NULL,
          activity_type TEXT NOT NULL,
          start_time TEXT NOT NULL,
          end_time TEXT NOT NULL,
          duration_seconds INTEGER NOT NULL,
          distance_km REAL NOT NULL,
          calories_burned REAL NOT NULL,
          route_json TEXT,
          created_at TEXT NOT NULL
        )
      ''');
    }

    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE ${TableNames.nutritionLogs} (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_email TEXT NOT NULL,
          food_name TEXT NOT NULL,
          calories REAL NOT NULL,
          protein REAL NOT NULL,
          carbs REAL NOT NULL,
          fat REAL NOT NULL,
          meal_type TEXT NOT NULL,
          grams REAL NOT NULL DEFAULT 100,
          selected_date TEXT NOT NULL,
          created_at TEXT NOT NULL
        )
      ''');
    }

    if (oldVersion < 5) {
      await db.execute('''
        CREATE TABLE ${TableNames.waterLogs} (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_email TEXT NOT NULL,
          amount_ml INTEGER NOT NULL,
          selected_date TEXT NOT NULL,
          created_at TEXT NOT NULL
        )
      ''');
    }

    if (oldVersion < 6) {
      await db.execute('''
        CREATE TABLE ${TableNames.workoutSessions} (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_email TEXT NOT NULL,
          category TEXT NOT NULL,
          program_name TEXT NOT NULL,
          total_exercises INTEGER NOT NULL,
          total_sets INTEGER NOT NULL,
          duration_seconds INTEGER NOT NULL,
          calories_burned REAL NOT NULL,
          completed INTEGER NOT NULL,
          created_at TEXT NOT NULL
        )
      ''');

      await db.execute('''
        CREATE TABLE ${TableNames.achievements} (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_email TEXT NOT NULL,
          title TEXT NOT NULL,
          description TEXT NOT NULL,
          created_at TEXT NOT NULL
        )
      ''');

      await db.execute('''
        CREATE TABLE ${TableNames.gameScores} (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_email TEXT NOT NULL,
          player_name TEXT NOT NULL DEFAULT '',
          game_name TEXT NOT NULL,
          score INTEGER NOT NULL,
          created_at TEXT NOT NULL
        )
      ''');
    }

    if (oldVersion < 7) {
      await db.execute(
        'ALTER TABLE ${TableNames.gameScores} ADD COLUMN player_name TEXT NOT NULL DEFAULT ""',
      );
    }
  }
}