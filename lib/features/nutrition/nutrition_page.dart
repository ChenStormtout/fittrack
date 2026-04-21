import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../data/models/food_item_model.dart';
import '../auth/controllers/auth_controller.dart';
import 'controllers/nutrition_controller.dart';

class NutritionPage extends StatefulWidget {
  const NutritionPage({super.key});

  @override
  State<NutritionPage> createState() => _NutritionPageState();
}

class _NutritionPageState extends State<NutritionPage> {
  final _searchController = TextEditingController();

  static const _mealTypes = [
    'Sarapan',
    'Makan Siang',
    'Makan Malam',
    'Camilan',
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final userEmail = context.read<AuthController>().userEmail;
    if (userEmail != null) {
      context.read<NutritionController>().loadDailyData(userEmail);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  double _targetCalories(BuildContext context) {
    final user = context.read<AuthController>().currentUser;
    if (user == null ||
        user.weightKg == null ||
        user.heightCm == null ||
        user.age == null ||
        user.gender == null) {
      return 2000;
    }

    final weight = user.weightKg!;
    final height = user.heightCm!;
    final age = user.age!;
    final gender = user.gender!;

    double bmr;
    if (gender == 'Male') {
      bmr = (10 * weight) + (6.25 * height) - (5 * age) + 5;
    } else {
      bmr = (10 * weight) + (6.25 * height) - (5 * age) - 161;
    }

    double multiplier = 1.4;
    switch (user.activityLevel) {
      case 'Tinggi':
        multiplier = 1.725;
        break;
      case 'Sedang':
        multiplier = 1.55;
        break;
      case 'Rendah':
      default:
        multiplier = 1.375;
    }

    double tdee = bmr * multiplier;

    switch (user.goal) {
      case 'Cutting':
        return tdee - 300;
      case 'Bulking':
        return tdee + 300;
      case 'Maintain':
      default:
        return tdee;
    }
  }

  double _targetProtein(BuildContext context) {
    final user = context.read<AuthController>().currentUser;
    if (user?.weightKg == null) return 110;
    return user!.weightKg! * 1.8;
  }

  int _targetWater(BuildContext context) {
    final user = context.read<AuthController>().currentUser;
    if (user?.weightKg == null) return 2000;
    return (user!.weightKg! * 35).round();
  }

  Future<void> _pickDate(
    BuildContext context,
    NutritionController nutritionController,
    String? userEmail,
  ) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: nutritionController.selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2100),
    );

    if (picked != null && userEmail != null) {
      nutritionController.changeDate(picked);
      await nutritionController.loadDailyData(userEmail);
    }
  }

  Future<void> _showAddFoodDialog({
    required BuildContext context,
    required FoodItemModel food,
    required NutritionController nutritionController,
    required String userEmail,
  }) async {
    String mealType = 'Sarapan';
    final gramsController = TextEditingController(text: '100');

    await showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text(food.name),
          content: StatefulBuilder(
            builder: (context, setStateDialog) {
              final grams = double.tryParse(gramsController.text) ?? 100;

              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: mealType,
                      items: _mealTypes
                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setStateDialog(() => mealType = value);
                        }
                      },
                      decoration: const InputDecoration(
                        labelText: 'Kategori makan',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: gramsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Jumlah (gram)',
                        hintText: 'Contoh: 100',
                      ),
                      onChanged: (_) => setStateDialog(() {}),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: [50, 100, 150, 200, 250].map((g) {
                        return ActionChip(
                          label: Text('$g g'),
                          onPressed: () {
                            gramsController.text = '$g';
                            setStateDialog(() {});
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    _dialogInfo('Kalori', '${food.caloriesFor(grams).toStringAsFixed(0)} kcal'),
                    _dialogInfo('Protein', '${food.proteinFor(grams).toStringAsFixed(1)} g'),
                    _dialogInfo('Karbo', '${food.carbsFor(grams).toStringAsFixed(1)} g'),
                    _dialogInfo('Lemak', '${food.fatFor(grams).toStringAsFixed(1)} g'),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                final grams = double.tryParse(gramsController.text) ?? 100;
                final success = await nutritionController.addFoodLog(
                  userEmail: userEmail,
                  food: food,
                  mealType: mealType,
                  grams: grams,
                );

                if (!context.mounted) return;
                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success ? 'Makanan ditambahkan' : 'Gagal menambahkan makanan',
                    ),
                  ),
                );
              },
              child: const Text('Tambah'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showAddWaterDialog({
    required BuildContext context,
    required NutritionController nutritionController,
    required String userEmail,
  }) async {
    final customController = TextEditingController();

    await showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Tambah Air Minum',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [250, 500, 1000].map((ml) {
                  return ElevatedButton(
                    onPressed: () async {
                      final success = await nutritionController.addWater(
                        userEmail: userEmail,
                        amountMl: ml,
                      );
                      if (!context.mounted) return;
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            success ? 'Air minum ditambahkan' : 'Gagal menambahkan air',
                          ),
                        ),
                      );
                    },
                    child: Text('+ $ml ml'),
                  );
                }).toList(),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: customController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Custom (ml)',
                  hintText: 'Contoh: 350',
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () async {
                  final custom = int.tryParse(customController.text) ?? 0;
                  if (custom <= 0) return;

                  final success = await nutritionController.addWater(
                    userEmail: userEmail,
                    amountMl: custom,
                  );

                  if (!context.mounted) return;
                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success ? 'Air minum ditambahkan' : 'Gagal menambahkan air',
                      ),
                    ),
                  );
                },
                child: const Text('Tambah Custom'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();
    final nutritionController = context.watch<NutritionController>();
    final user = authController.currentUser;

    final targetCalories = _targetCalories(context);
    final targetProtein = _targetProtein(context);
    final targetWater = _targetWater(context);

    final waterProgress =
        (nutritionController.totalWaterMl / targetWater).clamp(0.0, 1.0);
    final calorieProgress =
        (nutritionController.totalCalories / targetCalories).clamp(0.0, 1.0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nutrisi Harian'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          if (authController.userEmail != null) {
            await nutritionController.loadDailyData(authController.userEmail!);
          }
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            _HeaderDateCard(
              dateText: DateFormat('EEEE, dd MMM yyyy').format(nutritionController.selectedDate),
              goal: user?.goal ?? 'Maintain',
              onTapDate: () => _pickDate(
                context,
                nutritionController,
                authController.userEmail,
              ),
            ),
            const SizedBox(height: 16),
            _OverviewCard(
              totalCalories: nutritionController.totalCalories,
              targetCalories: targetCalories,
              totalProtein: nutritionController.totalProtein,
              totalCarbs: nutritionController.totalCarbs,
              totalFat: nutritionController.totalFat,
              calorieProgress: calorieProgress,
            ),
            const SizedBox(height: 16),
            _WaterCard(
              totalWaterMl: nutritionController.totalWaterMl,
              targetWaterMl: targetWater,
              progress: waterProgress,
              onAdd: authController.userEmail == null
                  ? null
                  : () => _showAddWaterDialog(
                        context: context,
                        nutritionController: nutritionController,
                        userEmail: authController.userEmail!,
                      ),
            ),
            const SizedBox(height: 16),
            _InsightCard(
              text: nutritionController.buildDailySummary(
                targetCalories: targetCalories,
                targetProtein: targetProtein,
                targetWaterMl: targetWater,
                goal: user?.goal ?? 'Maintain',
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Cari makanan',
                hintText: 'Contoh: chicken, bread, milk',
                suffixIcon: IconButton(
                  onPressed: () {
                    nutritionController.searchFoods(_searchController.text);
                  },
                  icon: const Icon(Icons.search),
                ),
              ),
              onSubmitted: nutritionController.searchFoods,
            ),
            const SizedBox(height: 14),
            if (nutritionController.isSearching)
              const Center(child: CircularProgressIndicator())
            else if (_searchController.text.isNotEmpty &&
                nutritionController.searchResults.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  'Makanan tidak ditemukan atau API tidak memberi hasil.',
                  textAlign: TextAlign.center,
                ),
              )
            else
              ...nutritionController.searchResults.take(8).map((food) {
                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    title: Text(
                      food.name,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      'per 100g • ${food.caloriesPer100g.toStringAsFixed(0)} kcal | '
                      'P ${food.proteinPer100g.toStringAsFixed(1)} | '
                      'C ${food.carbsPer100g.toStringAsFixed(1)} | '
                      'F ${food.fatPer100g.toStringAsFixed(1)}',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.add_circle, color: AppColors.primary),
                      onPressed: authController.userEmail == null
                          ? null
                          : () => _showAddFoodDialog(
                                context: context,
                                food: food,
                                nutritionController: nutritionController,
                                userEmail: authController.userEmail!,
                              ),
                    ),
                  ),
                );
              }),
            const SizedBox(height: 22),
            const Text(
              'Meal Log Hari Ini',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            ..._mealTypes.map((meal) {
              final logs = nutritionController.logsByMeal(meal);
              return _MealSection(
                title: meal,
                logs: logs,
              );
            }),
          ],
        ),
      ),
    );
  }

  static Widget _dialogInfo(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _HeaderDateCard extends StatelessWidget {
  const _HeaderDateCard({
    required this.dateText,
    required this.goal,
    required this.onTapDate,
  });

  final String dateText;
  final String goal;
  final VoidCallback onTapDate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.18),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.calendar_today_rounded, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Goal: $goal',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onTapDate,
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
            ),
            child: const Text('Ubah'),
          ),
        ],
      ),
    );
  }
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({
    required this.totalCalories,
    required this.targetCalories,
    required this.totalProtein,
    required this.totalCarbs,
    required this.totalFat,
    required this.calorieProgress,
  });

  final double totalCalories;
  final double targetCalories;
  final double totalProtein;
  final double totalCarbs;
  final double totalFat;
  final double calorieProgress;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Daily Overview',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            Text(
              '${totalCalories.toStringAsFixed(0)} / ${targetCalories.toStringAsFixed(0)} kcal',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                minHeight: 10,
                value: calorieProgress,
                backgroundColor: AppColors.softAccent,
                valueColor: const AlwaysStoppedAnimation(AppColors.primary),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _macroBox('Protein', '${totalProtein.toStringAsFixed(1)} g'),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _macroBox('Karbo', '${totalCarbs.toStringAsFixed(1)} g'),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _macroBox('Lemak', '${totalFat.toStringAsFixed(1)} g'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _macroBox(String title, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.softCard,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}

class _WaterCard extends StatelessWidget {
  const _WaterCard({
    required this.totalWaterMl,
    required this.targetWaterMl,
    required this.progress,
    required this.onAdd,
  });

  final int totalWaterMl;
  final int targetWaterMl;
  final double progress;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.softCard,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(Icons.water_drop_rounded, color: AppColors.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Water Intake',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text('$totalWaterMl / $targetWaterMl ml'),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      minHeight: 8,
                      value: progress,
                      backgroundColor: Colors.white,
                      valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            IconButton.filled(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              style: IconButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.softAccent,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.auto_awesome_rounded, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  height: 1.4,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MealSection extends StatelessWidget {
  const _MealSection({
    required this.title,
    required this.logs,
  });

  final String title;
  final List<dynamic> logs;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              if (logs.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.softCard,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text('Belum ada makanan'),
                )
              else
                ...logs.map((log) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.softCard,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.restaurant_menu, color: AppColors.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                log.foodName,
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${log.grams.toStringAsFixed(0)} g • '
                                '${log.calories.toStringAsFixed(0)} kcal',
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'P ${log.protein.toStringAsFixed(1)} • '
                                'C ${log.carbs.toStringAsFixed(1)} • '
                                'F ${log.fat.toStringAsFixed(1)}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }
}