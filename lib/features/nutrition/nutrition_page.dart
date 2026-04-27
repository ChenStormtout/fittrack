import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../data/models/food_item_model.dart';
import '../../data/models/nutrition_log_model.dart';
import '../../data/remote/food_scanner_service.dart';
import '../auth/controllers/auth_controller.dart';
import 'controllers/nutrition_controller.dart';

class NutritionPage extends StatefulWidget {
  const NutritionPage({super.key});

  @override
  State<NutritionPage> createState() => _NutritionPageState();
}

class _NutritionPageState extends State<NutritionPage> {
  final _searchController = TextEditingController();
  bool _loaded = false;

  static const _mealTypes = [
    'Sarapan',
    'Makan Siang',
    'Makan Malam',
    'Camilan',
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    _loaded = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userEmail = context.read<AuthController>().userEmail;
      if (userEmail != null) {
        context.read<NutritionController>().loadDailyData(userEmail);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _scanFoodPhoto(
    BuildContext context,
    NutritionController nutritionController,
    String? userEmail,
  ) async {
    // Pilih sumber foto
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const Text(
              'Foto Makanan',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text(
              'AI akan menganalisis kandungan nutrisi makanan dari foto',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _sourceButton(
                    icon: Icons.camera_alt_rounded,
                    label: 'Kamera',
                    onTap: () => Navigator.pop(context, ImageSource.camera),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _sourceButton(
                    icon: Icons.photo_library_rounded,
                    label: 'Galeri',
                    onTap: () => Navigator.pop(context, ImageSource.gallery),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (source == null) return;
    if (!context.mounted) return;

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 1024,
    );
    if (pickedFile == null) return;
    if (!context.mounted) return;

    final imageFile = File(pickedFile.path);

    // Tampilkan loading + hasil
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => _FoodScanResultSheet(
        imageFile: imageFile,
        userEmail: userEmail,
        nutritionController: nutritionController,
        mealTypes: _mealTypes,
      ),
    );
  }

  static Widget _sourceButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.softCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: AppColors.primary),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
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

    final tdee = bmr * multiplier;

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

  Future<void> _showEditFoodDialog({
    required BuildContext context,
    required NutritionLogModel log,
    required NutritionController nutritionController,
    required String userEmail,
  }) async {
    final gramsController = TextEditingController(
      text: log.grams.toStringAsFixed(0),
    );
    String mealType = log.mealType;

    await showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text('Edit ${log.foodName}'),
          content: StatefulBuilder(
            builder: (context, setStateDialog) {
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
                    TextField(
                      controller: gramsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Jumlah (gram)',
                      ),
                    ),
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
                final grams = double.tryParse(gramsController.text) ?? log.grams;

                final success = await nutritionController.updateFoodLog(
                  userEmail: userEmail,
                  oldLog: log,
                  grams: grams,
                  mealType: mealType,
                );

                if (!context.mounted) return;
                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success ? 'Makanan berhasil diupdate' : 'Gagal update makanan',
                    ),
                  ),
                );
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteFoodLog({
    required BuildContext context,
    required NutritionLogModel log,
    required NutritionController nutritionController,
    required String userEmail,
  }) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Hapus makanan'),
          content: Text('Yakin ingin menghapus ${log.foodName}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    final success = await nutritionController.deleteFoodLog(
      id: log.id as int,
      userEmail: userEmail,
    );

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? 'Makanan berhasil dihapus' : 'Gagal menghapus makanan',
        ),
      ),
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
            Row(
              children: [
                Expanded(
                  child: TextField(
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
                ),
                const SizedBox(width: 10),
                // Tombol kamera scan makanan
                Tooltip(
                  message: 'Scan foto makanan',
                  child: InkWell(
                    onTap: () => _scanFoodPhoto(
                      context,
                      nutritionController,
                      authController.userEmail,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.primaryLight],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.camera_alt_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ],
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
                onEdit: (log) {
                  if (authController.userEmail == null) return;
                  _showEditFoodDialog(
                    context: context,
                    log: log,
                    nutritionController: nutritionController,
                    userEmail: authController.userEmail!,
                  );
                },
                onDelete: (log) {
                  if (authController.userEmail == null) return;
                  _deleteFoodLog(
                    context: context,
                    log: log,
                    nutritionController: nutritionController,
                    userEmail: authController.userEmail!,
                  );
                },
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
    required this.onEdit,
    required this.onDelete,
  });

  final String title;
  final List<NutritionLogModel> logs;
  final Function(NutritionLogModel log) onEdit;
  final Function(NutritionLogModel log) onDelete;

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
                    child: Column(
                      children: [
                        Row(
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
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => onEdit(log),
                                icon: const Icon(Icons.edit_outlined),
                                label: const Text('Edit'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => onDelete(log),
                                icon: const Icon(Icons.delete_outline),
                                label: const Text('Hapus'),
                              ),
                            ),
                          ],
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

// ── FOOD SCAN RESULT BOTTOM SHEET ─────────────────────────────────────────────
class _FoodScanResultSheet extends StatefulWidget {
  const _FoodScanResultSheet({
    required this.imageFile,
    required this.userEmail,
    required this.nutritionController,
    required this.mealTypes,
  });

  final File imageFile;
  final String? userEmail;
  final NutritionController nutritionController;
  final List<String> mealTypes;

  @override
  State<_FoodScanResultSheet> createState() => _FoodScanResultSheetState();
}

class _FoodScanResultSheetState extends State<_FoodScanResultSheet> {
  List<FoodScanResult>? _results;
  bool _isAnalyzing = true;
  String _selectedMeal = 'Sarapan';
  FoodScanResult? _selectedResult;

  @override
  void initState() {
    super.initState();
    _analyze();
  }

  Future<void> _analyze() async {
    final results =
        await FoodScannerService.instance.analyzeImage(widget.imageFile);
    if (!mounted) return;
    setState(() {
      _results = results;
      _isAnalyzing = false;
      _selectedResult = results.isNotEmpty ? results.first : null;
    });
  }

  Future<void> _addToLog() async {
    final result = _selectedResult;
    if (result == null || widget.userEmail == null) return;

    const grams = 100.0;
    final success = await widget.nutritionController.addFoodLog(
      userEmail: widget.userEmail!,
      food: result.food,
      mealType: _selectedMeal,
      grams: grams,
    );

    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? '${result.food.name} berhasil ditambahkan ke log!'
              : 'Gagal menambahkan makanan',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, scrollController) {
        return SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.camera_enhance_rounded,
                        color: AppColors.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Analisis Foto Makanan',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            'Powered by AI',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.file(
                    widget.imageFile,
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 16),
                if (_isAnalyzing)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: AppColors.softCard,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Column(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 14),
                        Text(
                          'Menganalisis makanan...',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'AI sedang mendeteksi jenis dan menghitung nutrisi',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  )
                else if (_results == null || _results!.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.softCard,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Column(
                      children: [
                        Icon(
                          Icons.no_food_outlined,
                          size: 36,
                          color: AppColors.textSecondary,
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Makanan tidak terdeteksi',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Coba foto lebih jelas atau gunakan pencarian manual',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  )
                else ...[
                  const Text(
                    'Makanan Terdeteksi',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  ...(_results!.map((r) {
                    final isSelected = _selectedResult == r;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedResult = r),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary.withOpacity(0.08)
                              : AppColors.softCard,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color:
                                isSelected ? AppColors.primary : AppColors.border,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primary.withOpacity(0.15)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                Icons.restaurant_rounded,
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    r.food.name,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: isSelected
                                          ? AppColors.primary
                                          : AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${r.food.caloriesPer100g.toStringAsFixed(0)} kcal/100g • '
                                    'P ${r.food.proteinPer100g.toStringAsFixed(1)}g',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.softAccent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                r.confidencePercent,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected
                                      ? Colors.white
                                      : AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  })),
                  if (_selectedResult != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.softCard,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Informasi Nutrisi (per 100g)',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              _nutriCell(
                                'Kalori',
                                '${_selectedResult!.food.caloriesPer100g.toStringAsFixed(0)}',
                                'kcal',
                                const Color(0xFFE91E63),
                              ),
                              _nutriCell(
                                'Protein',
                                '${_selectedResult!.food.proteinPer100g.toStringAsFixed(1)}',
                                'g',
                                const Color(0xFF2196F3),
                              ),
                              _nutriCell(
                                'Karbo',
                                '${_selectedResult!.food.carbsPer100g.toStringAsFixed(1)}',
                                'g',
                                const Color(0xFFFF9800),
                              ),
                              _nutriCell(
                                'Lemak',
                                '${_selectedResult!.food.fatPer100g.toStringAsFixed(1)}',
                                'g',
                                const Color(0xFF4CAF50),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      value: _selectedMeal,
                      decoration: const InputDecoration(
                        labelText: 'Tambah ke kategori',
                      ),
                      items: widget.mealTypes
                          .map(
                            (e) => DropdownMenuItem(value: e, child: Text(e)),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _selectedMeal = v);
                      },
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed:
                            widget.userEmail == null ? null : _addToLog,
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: const Icon(Icons.add_circle_rounded),
                        label: Text(
                          'Tambah ${_selectedResult!.food.name} ke Log',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _nutriCell(
      String label, String value, String unit, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            '$value $unit',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 14,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}