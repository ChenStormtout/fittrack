class FoodItemModel {
  final String name;

  // basis per 100 gram
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

  factory FoodItemModel.fromOpenFoodFacts(Map<String, dynamic> map) {
    final nutriments = (map['nutriments'] as Map<String, dynamic>? ?? {});

    return FoodItemModel(
      name: (map['product_name'] ?? map['product_name_en'] ?? 'Unknown Food').toString(),
      caloriesPer100g: (nutriments['energy-kcal_100g'] as num?)?.toDouble() ??
          ((nutriments['energy-kcal'] as num?)?.toDouble() ?? 0),
      proteinPer100g: (nutriments['proteins_100g'] as num?)?.toDouble() ?? 0,
      carbsPer100g: (nutriments['carbohydrates_100g'] as num?)?.toDouble() ?? 0,
      fatPer100g: (nutriments['fat_100g'] as num?)?.toDouble() ?? 0,
    );
  }

  double caloriesFor(double grams) => caloriesPer100g * grams / 100;
  double proteinFor(double grams) => proteinPer100g * grams / 100;
  double carbsFor(double grams) => carbsPer100g * grams / 100;
  double fatFor(double grams) => fatPer100g * grams / 100;
}