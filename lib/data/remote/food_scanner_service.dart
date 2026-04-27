import 'dart:io';
import 'dart:math';

import '../../data/models/food_item_model.dart';

/// Service simulasi analisis foto makanan menggunakan AI mock.
/// Dalam implementasi nyata, ini akan memanggil Vision API seperti
/// Google Cloud Vision + Nutritionix atau Open Food Facts.
class FoodScannerService {
  FoodScannerService._();
  static final FoodScannerService instance = FoodScannerService._();

  // Database makanan Indonesia & umum untuk simulasi
  static const List<Map<String, dynamic>> _foodDatabase = [
    {
      'name': 'Nasi Putih',
      'calories': 130.0,
      'protein': 2.7,
      'carbs': 28.2,
      'fat': 0.3,
      'keywords': ['nasi', 'rice', 'putih', 'white'],
    },
    {
      'name': 'Ayam Goreng',
      'calories': 246.0,
      'protein': 26.0,
      'carbs': 2.0,
      'fat': 14.0,
      'keywords': ['ayam', 'goreng', 'chicken', 'fried'],
    },
    {
      'name': 'Telur Goreng',
      'calories': 185.0,
      'protein': 12.8,
      'carbs': 0.4,
      'fat': 14.3,
      'keywords': ['telur', 'egg', 'goreng'],
    },
    {
      'name': 'Mie Goreng',
      'calories': 165.0,
      'protein': 4.5,
      'carbs': 26.0,
      'fat': 5.5,
      'keywords': ['mie', 'mie goreng', 'noodle'],
    },
    {
      'name': 'Rendang Daging',
      'calories': 193.0,
      'protein': 14.0,
      'carbs': 4.3,
      'fat': 13.0,
      'keywords': ['rendang', 'daging', 'beef'],
    },
    {
      'name': 'Gado-Gado',
      'calories': 116.0,
      'protein': 5.2,
      'carbs': 12.1,
      'fat': 5.6,
      'keywords': ['gado', 'sayur', 'peanut', 'vegetables'],
    },
    {
      'name': 'Soto Ayam',
      'calories': 95.0,
      'protein': 8.5,
      'carbs': 7.0,
      'fat': 3.5,
      'keywords': ['soto', 'soup', 'ayam'],
    },
    {
      'name': 'Pisang',
      'calories': 89.0,
      'protein': 1.1,
      'carbs': 23.0,
      'fat': 0.3,
      'keywords': ['pisang', 'banana', 'fruit', 'buah'],
    },
    {
      'name': 'Roti Tawar',
      'calories': 265.0,
      'protein': 9.0,
      'carbs': 49.0,
      'fat': 3.2,
      'keywords': ['roti', 'bread', 'toast'],
    },
    {
      'name': 'Salad Sayur',
      'calories': 35.0,
      'protein': 2.0,
      'carbs': 7.0,
      'fat': 0.5,
      'keywords': ['salad', 'sayur', 'vegetables', 'greens'],
    },
    {
      'name': 'Tempe Goreng',
      'calories': 193.0,
      'protein': 15.0,
      'carbs': 9.0,
      'fat': 11.0,
      'keywords': ['tempe', 'tempeh'],
    },
    {
      'name': 'Tahu Goreng',
      'calories': 271.0,
      'protein': 17.0,
      'carbs': 10.0,
      'fat': 19.0,
      'keywords': ['tahu', 'tofu'],
    },
    {
      'name': 'Bakso',
      'calories': 169.0,
      'protein': 12.0,
      'carbs': 10.5,
      'fat': 8.5,
      'keywords': ['bakso', 'meatball'],
    },
    {
      'name': 'Nasi Goreng',
      'calories': 163.0,
      'protein': 5.0,
      'carbs': 26.0,
      'fat': 5.0,
      'keywords': ['nasi goreng', 'fried rice'],
    },
    {
      'name': 'Buah Apel',
      'calories': 52.0,
      'protein': 0.3,
      'carbs': 14.0,
      'fat': 0.2,
      'keywords': ['apel', 'apple', 'fruit', 'buah'],
    },
  ];

  /// Analisis foto makanan. Mengembalikan daftar kemungkinan makanan
  /// yang terdeteksi beserta perkiraan nutrisinya.
  ///
  /// [imageFile] — foto dari camera/gallery
  /// Delay 2 detik untuk simulasi AI processing.
  Future<List<FoodScanResult>> analyzeImage(File imageFile) async {
    // Simulasi delay AI processing
    await Future.delayed(const Duration(milliseconds: 2200));

    // Dalam implementasi nyata: kirim image ke Vision API,
    // dapat label makanan, lalu query Nutritionix / USDA.
    // Untuk demo: random pilih 2-3 makanan yang masuk akal.
    final random = Random();
    final shuffled = List<Map<String, dynamic>>.from(_foodDatabase)..shuffle(random);
    final count = 1 + random.nextInt(2); // 1-2 deteksi
    final selected = shuffled.take(count).toList();

    return selected.map((data) {
      final confidence = 0.72 + random.nextDouble() * 0.25; // 72-97%
      return FoodScanResult(
        food: FoodItemModel(
          name: data['name'] as String,
          caloriesPer100g: data['calories'] as double,
          proteinPer100g: data['protein'] as double,
          carbsPer100g: data['carbs'] as double,
          fatPer100g: data['fat'] as double,
        ),
        confidence: confidence,
        detectedLabel: data['name'] as String,
      );
    }).toList()
      ..sort((a, b) => b.confidence.compareTo(a.confidence));
  }
}

class FoodScanResult {
  final FoodItemModel food;
  final double confidence; // 0.0 - 1.0
  final String detectedLabel;

  const FoodScanResult({
    required this.food,
    required this.confidence,
    required this.detectedLabel,
  });

  String get confidencePercent => '${(confidence * 100).toStringAsFixed(0)}%';
}
