import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'app.dart';
import 'core/services/crypto_service.dart';
import 'core/services/secure_storage_service.dart';
import 'data/local/db/app_database.dart';
import 'data/remote/food_api_service.dart';
import 'data/repositories/activity_repository.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/nutrition_repository.dart';
import 'data/repositories/workout_repository.dart';

import 'features/activity/controllers/activity_controller.dart';
import 'features/activity/controllers/workout_controller.dart';
import 'features/auth/controllers/auth_controller.dart';
import 'features/nutrition/controllers/nutrition_controller.dart';
import 'features/minigame/controllers/minigame_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb && (Platform.isWindows || Platform.isLinux)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  final secureStorageService = SecureStorageService();
  final cryptoService = CryptoService();
  final appDatabase = AppDatabase.instance;

  final authRepository = AuthRepository(
    appDatabase: appDatabase,
    cryptoService: cryptoService,
  );

  final activityRepository = ActivityRepository(appDatabase: appDatabase);
  final nutritionRepository = NutritionRepository(appDatabase: appDatabase);
  final workoutRepository = WorkoutRepository(appDatabase: appDatabase);
  final foodApiService = FoodApiService();

  final authController = AuthController(
    secureStorageService: secureStorageService,
    authRepository: authRepository,
  );

  await authController.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthController>.value(value: authController),

        ChangeNotifierProvider<ActivityController>(
          create: (_) => ActivityController(
            activityRepository: activityRepository,
          ),
        ),

        ChangeNotifierProvider<NutritionController>(
          create: (_) => NutritionController(
            foodApiService: foodApiService,
            nutritionRepository: nutritionRepository,
          ),
        ),

        ChangeNotifierProvider<WorkoutController>(
          create: (_) => WorkoutController(
            workoutRepository: workoutRepository,
          ),
        ),

        ChangeNotifierProvider<MinigameController>(
          create: (_) => MinigameController(
            workoutRepository: workoutRepository,
          ),
        ),
      ],
      child: const FitLifeApp(),
    ),
  );
}