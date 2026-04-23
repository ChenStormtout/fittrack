class FoodItemModel {
  final String name;
  final double caloriesPer100g;
  final double proteinPer100g;
  final double carbsPer100g;
  final double fatPer100g;

  FoodItemModel({
    required this.name,
    required this.caloriesPer100g,
    required this.proteinPer100g,
    required this.carbsPer100g,
    required this.fatPer100g,
  });

  static double _asDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  static double _extractNutrientValue(
    List<dynamic> nutrients, {
    List<String> nutrientNumbers = const [],
    List<String> nutrientNames = const [],
  }) {
    for (final item in nutrients) {
      if (item is! Map<String, dynamic>) continue;

      final nutrientNumber = item['nutrientNumber']?.toString().trim() ?? '';
      final nutrientName =
          (item['nutrientName'] ?? item['name'] ?? '').toString().toLowerCase().trim();

      if (nutrientNumbers.contains(nutrientNumber)) {
        return _asDouble(item['value']);
      }

      for (final name in nutrientNames) {
        if (nutrientName.contains(name.toLowerCase())) {
          return _asDouble(item['value']);
        }
      }
    }

    return 0;
  }

  factory FoodItemModel.fromUsda(Map<String, dynamic> map) {
    final nutrients = (map['foodNutrients'] as List<dynamic>? ?? []);

    final calories = _extractNutrientValue(
      nutrients,
      nutrientNumbers: ['1008'],
      nutrientNames: ['energy'],
    );

    final protein = _extractNutrientValue(
      nutrients,
      nutrientNumbers: ['1003'],
      nutrientNames: ['protein'],
    );

    final carbs = _extractNutrientValue(
      nutrients,
      nutrientNumbers: ['1005'],
      nutrientNames: ['carbohydrate'],
    );

    final fat = _extractNutrientValue(
      nutrients,
      nutrientNumbers: ['1004'],
      nutrientNames: ['total lipid', 'fat'],
    );

    return FoodItemModel(
      name: (map['description'] ?? 'Unknown Food').toString(),
      caloriesPer100g: calories,
      proteinPer100g: protein,
      carbsPer100g: carbs,
      fatPer100g: fat,
    );
  }

  double caloriesFor(double grams) => caloriesPer100g * grams / 100;
  double proteinFor(double grams) => proteinPer100g * grams / 100;
  double carbsFor(double grams) => carbsPer100g * grams / 100;
  double fatFor(double grams) => fatPer100g * grams / 100;
}