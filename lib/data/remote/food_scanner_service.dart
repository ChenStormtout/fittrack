import 'dart:io';

import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';

import '../../data/models/food_item_model.dart';
import '../../data/remote/food_api_service.dart';

class FoodScanResult {
  final FoodItemModel food;
  final double confidence;
  final String detectedLabel;
  final String source;

  const FoodScanResult({
    required this.food,
    required this.confidence,
    required this.detectedLabel,
    required this.source,
  });

  String get confidencePercent => '${(confidence * 100).toStringAsFixed(0)}%';
}

class FoodScannerService {
  FoodScannerService._();

  static final FoodScannerService instance = FoodScannerService._();

  final FoodApiService _foodApiService = FoodApiService();

  static const Map<String, Map<String, dynamic>> _localNutritionMap = {
    'apple': {
      'name': 'Apel',
      'calories': 52.0,
      'protein': 0.3,
      'carbs': 14.0,
      'fat': 0.2,
    },
    'banana': {
      'name': 'Pisang',
      'calories': 89.0,
      'protein': 1.1,
      'carbs': 23.0,
      'fat': 0.3,
    },
    'orange': {
      'name': 'Jeruk',
      'calories': 47.0,
      'protein': 0.9,
      'carbs': 12.0,
      'fat': 0.1,
    },
    'mango': {
      'name': 'Mangga',
      'calories': 60.0,
      'protein': 0.8,
      'carbs': 15.0,
      'fat': 0.4,
    },
    'rice': {
      'name': 'Nasi',
      'calories': 130.0,
      'protein': 2.7,
      'carbs': 28.2,
      'fat': 0.3,
    },
    'chicken': {
      'name': 'Ayam',
      'calories': 165.0,
      'protein': 31.0,
      'carbs': 0.0,
      'fat': 3.6,
    },
    'egg': {
      'name': 'Telur',
      'calories': 155.0,
      'protein': 13.0,
      'carbs': 1.1,
      'fat': 11.0,
    },
    'bread': {
      'name': 'Roti',
      'calories': 265.0,
      'protein': 9.0,
      'carbs': 49.0,
      'fat': 3.2,
    },
    'noodle': {
      'name': 'Mie',
      'calories': 138.0,
      'protein': 4.5,
      'carbs': 25.0,
      'fat': 2.0,
    },
    'salad': {
      'name': 'Salad',
      'calories': 35.0,
      'protein': 2.0,
      'carbs': 7.0,
      'fat': 0.5,
    },
  };

  static const Map<String, List<String>> _aliases = {
    'apple': ['apple', 'apel'],
    'banana': ['banana', 'pisang'],
    'orange': ['orange', 'jeruk'],
    'mango': ['mango', 'mangga'],
    'rice': ['rice', 'nasi', 'white rice', 'cooked rice'],
    'chicken': ['chicken', 'ayam', 'poultry'],
    'egg': ['egg', 'telur'],
    'bread': ['bread', 'roti', 'toast'],
    'noodle': ['noodle', 'mie', 'noodles'],
    'salad': ['salad', 'vegetable salad'],
  };

  static const Set<String> _genericLabels = {
    'food',
    'dish',
    'meal',
    'cuisine',
    'ingredient',
    'tableware',
    'plate',
    'bowl',
    'recipe',
    'produce',
    'vegetable',
    'fruit',
  };

  Future<List<FoodScanResult>> analyzeImage(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);

    final labeler = ImageLabeler(
      options: ImageLabelerOptions(
        confidenceThreshold: 0.45,
      ),
    );

    try {
      final labels = await labeler.processImage(inputImage);
      await labeler.close();

      if (labels.isEmpty) return [];

      final results = <FoodScanResult>[];

      for (final label in labels) {
        final detectedLabel = label.label.trim();
        final normalizedLabel = detectedLabel.toLowerCase();

        if (_genericLabels.contains(normalizedLabel)) {
          continue;
        }

        final localResult = _getLocalNutritionResult(
          label: normalizedLabel,
          originalLabel: detectedLabel,
          confidence: label.confidence,
        );

        if (localResult != null) {
          results.add(localResult);
          continue;
        }

        final apiResults = await _getUsdaNutritionResults(
          query: detectedLabel,
          confidence: label.confidence,
        );

        results.addAll(apiResults);
      }

      final uniqueResults = _removeDuplicateFoods(results);
      uniqueResults.sort((a, b) => b.confidence.compareTo(a.confidence));

      return uniqueResults.take(5).toList();
    } catch (e) {
      await labeler.close();
      return [];
    }
  }

  FoodScanResult? _getLocalNutritionResult({
    required String label,
    required String originalLabel,
    required double confidence,
  }) {
    final matchKey = _findLocalMatch(label);

    if (matchKey == null) return null;

    final data = _localNutritionMap[matchKey]!;

    return FoodScanResult(
      food: FoodItemModel(
        name: data['name'] as String,
        caloriesPer100g: data['calories'] as double,
        proteinPer100g: data['protein'] as double,
        carbsPer100g: data['carbs'] as double,
        fatPer100g: data['fat'] as double,
      ),
      confidence: confidence,
      detectedLabel: originalLabel,
      source: 'Database lokal',
    );
  }

  String? _findLocalMatch(String label) {
    for (final entry in _aliases.entries) {
      final foodKey = entry.key;
      final aliases = entry.value;

      for (final alias in aliases) {
        final normalizedAlias = alias.toLowerCase();

        if (label.contains(normalizedAlias) ||
            normalizedAlias.contains(label)) {
          return foodKey;
        }
      }
    }

    return null;
  }

  Future<List<FoodScanResult>> _getUsdaNutritionResults({
    required String query,
    required double confidence,
  }) async {
    try {
      final foods = await _foodApiService.searchFoods(query);

      return foods.take(3).map((food) {
        return FoodScanResult(
          food: food,
          confidence: confidence,
          detectedLabel: query,
          source: 'USDA FoodData Central API',
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  List<FoodScanResult> _removeDuplicateFoods(List<FoodScanResult> results) {
    final seen = <String>{};
    final unique = <FoodScanResult>[];

    for (final result in results) {
      final key = result.food.name.toLowerCase().trim();

      if (!seen.contains(key)) {
        seen.add(key);
        unique.add(result);
      }
    }

    return unique;
  }
}