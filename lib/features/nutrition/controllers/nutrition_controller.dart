import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../../../data/models/food_item_model.dart';
import '../../../data/models/nutrition_log_model.dart';
import '../../../data/models/water_log_model.dart';
import '../../../data/remote/food_api_service.dart';
import '../../../data/repositories/nutrition_repository.dart';

class NutritionController extends ChangeNotifier {
  NutritionController({
    required FoodApiService foodApiService,
    required NutritionRepository nutritionRepository,
  })  : _foodApiService = foodApiService,
        _nutritionRepository = nutritionRepository;

  final FoodApiService _foodApiService;
  final NutritionRepository _nutritionRepository;

  bool _isSearching = false;
  bool _isSaving = false;

  List<FoodItemModel> _searchResults = [];
  List<NutritionLogModel> _dailyLogs = [];
  List<WaterLogModel> _dailyWaterLogs = [];

  DateTime _selectedDate = DateTime.now();

  bool get isSearching => _isSearching;
  bool get isSaving => _isSaving;
  List<FoodItemModel> get searchResults => _searchResults;
  List<NutritionLogModel> get dailyLogs => _dailyLogs;
  List<WaterLogModel> get dailyWaterLogs => _dailyWaterLogs;
  DateTime get selectedDate => _selectedDate;
  String get selectedDateKey => DateFormat('yyyy-MM-dd').format(_selectedDate);

  double get totalCalories => _dailyLogs.fold(0.0, (sum, item) => sum + item.calories);
  double get totalProtein => _dailyLogs.fold(0.0, (sum, item) => sum + item.protein);
  double get totalCarbs => _dailyLogs.fold(0.0, (sum, item) => sum + item.carbs);
  double get totalFat => _dailyLogs.fold(0.0, (sum, item) => sum + item.fat);

  int get totalWaterMl => _dailyWaterLogs.fold(0, (sum, item) => sum + item.amountMl);

  List<NutritionLogModel> logsByMeal(String mealType) {
    return _dailyLogs.where((e) => e.mealType == mealType).toList();
  }

  Future<void> searchFoods(String query) async {
    _isSearching = true;
    notifyListeners();

    try {
      _searchResults = await _foodApiService.searchFoods(query);
    } catch (_) {
      _searchResults = [];
    }

    _isSearching = false;
    notifyListeners();
  }

  void changeDate(DateTime newDate) {
    _selectedDate = newDate;
    notifyListeners();
  }

  Future<void> loadDailyData(String userEmail) async {
    _dailyLogs = await _nutritionRepository.getLogsByDate(
      userEmail: userEmail,
      selectedDate: selectedDateKey,
    );

    _dailyWaterLogs = await _nutritionRepository.getWaterLogsByDate(
      userEmail: userEmail,
      selectedDate: selectedDateKey,
    );

    notifyListeners();
  }


  Future<bool> deleteFoodLog({
  required int id,
  required String userEmail,
}) async {
  try {
    await _nutritionRepository.deleteLog(id);
    await loadDailyData(userEmail);
    return true;
  } catch (_) {
    return false;
  }
}

  Future<bool> updateFoodLog({
    required String userEmail,
    required NutritionLogModel oldLog,
    required double grams,
    required String mealType,
  }) async {
    try {
      final factor = grams / oldLog.grams;

      final updated = NutritionLogModel(
        id: oldLog.id,
        userEmail: oldLog.userEmail,
        foodName: oldLog.foodName,
        calories: oldLog.calories * factor,
        protein: oldLog.protein * factor,
        carbs: oldLog.carbs * factor,
        fat: oldLog.fat * factor,
        mealType: mealType,
        grams: grams,
        selectedDate: oldLog.selectedDate,
        createdAt: oldLog.createdAt,
      );

      await _nutritionRepository.updateLog(updated);
      await loadDailyData(userEmail);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> addFoodLog({
    required String userEmail,
    required FoodItemModel food,
    required String mealType,
    required double grams,
  }) async {
    _isSaving = true;
    notifyListeners();

    try {
      final log = NutritionLogModel(
        userEmail: userEmail.trim().toLowerCase(),
        foodName: food.name,
        calories: food.caloriesFor(grams),
        protein: food.proteinFor(grams),
        carbs: food.carbsFor(grams),
        fat: food.fatFor(grams),
        mealType: mealType,
        grams: grams,
        selectedDate: selectedDateKey,
        createdAt: DateTime.now().toIso8601String(),
      );

      await _nutritionRepository.insertLog(log);
      await loadDailyData(userEmail);

      _isSaving = false;
      notifyListeners();
      return true;
    } catch (_) {
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> addWater({
    required String userEmail,
    required int amountMl,
  }) async {
    try {
      final log = WaterLogModel(
        userEmail: userEmail.trim().toLowerCase(),
        amountMl: amountMl,
        selectedDate: selectedDateKey,
        createdAt: DateTime.now().toIso8601String(),
      );

      await _nutritionRepository.insertWaterLog(log);
      await loadDailyData(userEmail);
      return true;
    } catch (_) {
      return false;
    }
  }

  String buildDailySummary({
    required double targetCalories,
    required double targetProtein,
    required int targetWaterMl,
    required String goal,
  }) {
    final calorieDiff = targetCalories - totalCalories;
    final proteinDiff = targetProtein - totalProtein;
    final waterDiff = targetWaterMl - totalWaterMl;

    String calorieText;
    if (calorieDiff > 120) {
      calorieText = 'Kalori masih kurang ${calorieDiff.toStringAsFixed(0)} kcal.';
    } else if (calorieDiff < -120) {
      calorieText = 'Kalori melebihi target ${(-calorieDiff).toStringAsFixed(0)} kcal.';
    } else {
      calorieText = 'Kalori sudah mendekati target.';
    }

    String proteinText;
    if (proteinDiff > 10) {
      proteinText = 'Protein masih kurang ${proteinDiff.toStringAsFixed(0)} g.';
    } else {
      proteinText = 'Protein sudah cukup baik.';
    }

    String waterText;
    if (waterDiff > 250) {
      waterText = 'Air minum masih kurang $waterDiff ml.';
    } else {
      waterText = 'Hidrasi hari ini cukup baik.';
    }

    return 'Goal: $goal. $calorieText $proteinText $waterText';
  }
}