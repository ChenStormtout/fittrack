class NutritionLogModel {
  final int? id;
  final String userEmail;
  final String foodName;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final String mealType;
  final double grams;
  final String selectedDate;
  final String createdAt;

  NutritionLogModel({
    this.id,
    required this.userEmail,
    required this.foodName,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.mealType,
    required this.grams,
    required this.selectedDate,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_email': userEmail,
      'food_name': foodName,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'meal_type': mealType,
      'grams': grams,
      'selected_date': selectedDate,
      'created_at': createdAt,
    };
  }

  factory NutritionLogModel.fromMap(Map<String, dynamic> map) {
    return NutritionLogModel(
      id: map['id'] as int?,
      userEmail: map['user_email'] as String,
      foodName: map['food_name'] as String,
      calories: (map['calories'] as num).toDouble(),
      protein: (map['protein'] as num).toDouble(),
      carbs: (map['carbs'] as num).toDouble(),
      fat: (map['fat'] as num).toDouble(),
      mealType: map['meal_type'] as String,
      grams: (map['grams'] as num?)?.toDouble() ?? 100,
      selectedDate: map['selected_date'] as String,
      createdAt: map['created_at'] as String,
    );
  }
}