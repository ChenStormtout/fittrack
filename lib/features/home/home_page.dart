// home_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../data/models/activity_model.dart';
import '../../data/models/workout_session_model.dart';
import '../activity/controllers/activity_controller.dart';
import '../activity/controllers/workout_controller.dart';
import '../auth/controllers/auth_controller.dart';
import '../minigame/minigame_page.dart';
import '../nutrition/controllers/nutrition_controller.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    _loaded = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final email = context.read<AuthController>().userEmail;
      if (email != null) {
        context.read<NutritionController>().loadDailyData(email);
        context.read<ActivityController>().loadHistory(email);
        context.read<WorkoutController>().loadHistory(email);
      }
    });
  }

  double _targetCalories(BuildContext context) {
    final user = context.read<AuthController>().currentUser;
    if (user == null ||
        user.weightKg == null ||
        user.heightCm == null ||
        user.age == null ||
        user.gender == null) return 2000;
    final w = user.weightKg!;
    final h = user.heightCm!;
    final a = user.age!;
    double bmr = user.gender == 'Male'
        ? (10 * w) + (6.25 * h) - (5 * a) + 5
        : (10 * w) + (6.25 * h) - (5 * a) - 161;
    double mult = 1.4;
    if (user.activityLevel == 'Tinggi') mult = 1.725;
    if (user.activityLevel == 'Sedang') mult = 1.55;
    final tdee = bmr * mult;
    if (user.goal == 'Cutting') return tdee - 300;
    if (user.goal == 'Bulking') return tdee + 300;
    return tdee;
  }

  int _targetWater(BuildContext context) {
    final user = context.read<AuthController>().currentUser;
    if (user?.weightKg == null) return 2000;
    return (user!.weightKg! * 35).round();
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 11) return 'Selamat Pagi';
    if (h < 15) return 'Selamat Siang';
    if (h < 18) return 'Selamat Sore';
    return 'Selamat Malam';
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final nutrition = context.watch<NutritionController>();
    final activityCtrl = context.watch<ActivityController>();
    final workoutCtrl = context.watch<WorkoutController>();

    final user = auth.currentUser;
    final name = (user?.fullName?.trim().isNotEmpty ?? false)
        ? user!.fullName!.split(' ').first
        : 'Sobat';

    final targetCal = _targetCalories(context);
    final targetWater = _targetWater(context);
    final calProgress = (nutrition.totalCalories / targetCal).clamp(0.0, 1.0);
    final waterProgress =
        (nutrition.totalWaterMl / targetWater).clamp(0.0, 1.0);
    final remainingCal = (targetCal - nutrition.totalCalories).clamp(0, 9999);

    // Gabungkan semua sesi latihan hari ini
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final todayOutdoor = activityCtrl.history
        .where((a) => a.createdAt.startsWith(today))
        .toList();
    final todayGym = workoutCtrl.history
        .where((w) => w.createdAt.startsWith(today))
        .toList();
    final totalSessionsToday = todayOutdoor.length + todayGym.length;
    final totalCalBurned = todayOutdoor.fold<double>(
            0, (s, a) => s + a.caloriesBurned) +
        todayGym.fold<double>(0, (s, w) => s + w.caloriesBurned);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── HEADER ──────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _Header(
              greeting: _greeting(),
              name: name,
              goal: user?.goal ?? 'Maintain',
              date: DateFormat('EEEE, dd MMM').format(DateTime.now()),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 20),

                // ── KALORI RING CARD ───────────────────────────────
                _CalorieRingCard(
                  consumed: nutrition.totalCalories,
                  target: targetCal,
                  remaining: remainingCal.toDouble(),
                  progress: calProgress,
                  protein: nutrition.totalProtein,
                  carbs: nutrition.totalCarbs,
                  fat: nutrition.totalFat,
                ),

                const SizedBox(height: 14),

                // ── STATS ROW ──────────────────────────────────────
                Row(children: [
                  Expanded(
                    child: _StatMiniCard(
                      icon: Icons.water_drop_rounded,
                      color: const Color(0xFF2196F3),
                      label: 'Air Minum',
                      value:
                          '${(nutrition.totalWaterMl / 1000).toStringAsFixed(1)}L',
                      sub:
                          '/ ${(targetWater / 1000).toStringAsFixed(1)}L',
                      progress: waterProgress,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatMiniCard(
                      icon: Icons.local_fire_department_rounded,
                      color: const Color(0xFFE91E63),
                      label: 'Kalori Terbakar',
                      value:
                          '${totalCalBurned.toStringAsFixed(0)}',
                      sub: 'kcal hari ini',
                      progress: (totalCalBurned / 500).clamp(0.0, 1.0),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatMiniCard(
                      icon: Icons.fitness_center_rounded,
                      color: const Color(0xFF9C27B0),
                      label: 'Sesi Latihan',
                      value: '$totalSessionsToday',
                      sub: 'sesi hari ini',
                      progress: (totalSessionsToday / 3).clamp(0.0, 1.0),
                    ),
                  ),
                ]),

                const SizedBox(height: 20),

                // ── DAILY INSIGHT ──────────────────────────────────
                _InsightBanner(
                  totalCalories: nutrition.totalCalories,
                  targetCalories: targetCal,
                  totalWater: nutrition.totalWaterMl,
                  targetWater: targetWater,
                  sessions: totalSessionsToday,
                  goal: user?.goal ?? 'Maintain',
                ),

                const SizedBox(height: 20),

                // ── AKTIVITAS TERAKHIR ─────────────────────────────
                if (activityCtrl.history.isNotEmpty ||
                    workoutCtrl.history.isNotEmpty) ...[
                  _SectionHeader(
                    title: 'Aktivitas Terakhir',
                    icon: Icons.history_rounded,
                  ),
                  const SizedBox(height: 10),
                  _LastActivityCard(
                    outdoor: activityCtrl.history.isNotEmpty
                        ? activityCtrl.history.first
                        : null,
                    gym: workoutCtrl.history.isNotEmpty
                        ? workoutCtrl.history.first
                        : null,
                  ),
                  const SizedBox(height: 20),
                ],

                // ── MINI GAME ──────────────────────────────────────
                _SectionHeader(
                  title: 'Mini Game',
                  icon: Icons.sports_esports_rounded,
                ),
                const SizedBox(height: 10),
                _GameCard(
                  onPlay: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const MinigamePage()),
                  ),
                ),

                const SizedBox(height: 20),

                // ── QUICK TIPS ─────────────────────────────────────
                _QuickTip(goal: user?.goal ?? 'Maintain'),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// HEADER
// ════════════════════════════════════════════════════════════════
class _Header extends StatelessWidget {
  const _Header({
    required this.greeting,
    required this.name,
    required this.goal,
    required this.date,
  });

  final String greeting, name, goal, date;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 56, 20, 28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    greeting,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.75),
                        fontSize: 13),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -.5,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.flag_rounded,
                    color: Colors.white, size: 13),
                const SizedBox(width: 5),
                Text(goal,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700)),
              ]),
            ),
          ]),
          const SizedBox(height: 6),
          Text(date,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.6), fontSize: 12)),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// CALORIE RING CARD
// ════════════════════════════════════════════════════════════════
class _CalorieRingCard extends StatelessWidget {
  const _CalorieRingCard({
    required this.consumed,
    required this.target,
    required this.remaining,
    required this.progress,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  final double consumed, target, remaining, progress, protein, carbs, fat;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 16,
              offset: const Offset(0, 6))
        ],
      ),
      child: Column(children: [
        Row(children: [
          // Ring
          SizedBox(
            width: 110,
            height: 110,
            child: Stack(alignment: Alignment.center, children: [
              SizedBox(
                width: 110,
                height: 110,
                child: CircularProgressIndicator(
                  value: 1,
                  strokeWidth: 10,
                  color: AppColors.softAccent,
                ),
              ),
              SizedBox(
                width: 110,
                height: 110,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 10,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation(
                    progress > 1.0
                        ? AppColors.error
                        : AppColors.primary,
                  ),
                  strokeCap: StrokeCap.round,
                ),
              ),
              Column(mainAxisSize: MainAxisSize.min, children: [
                Text(
                  consumed.toStringAsFixed(0),
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary),
                ),
                const Text('kcal',
                    style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary)),
              ]),
            ]),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _calorieRow('Target', target, AppColors.textSecondary),
                  const SizedBox(height: 8),
                  _calorieRow(
                      remaining < 0 ? 'Kelebihan' : 'Sisa',
                      remaining.abs(),
                      remaining < 0
                          ? AppColors.error
                          : AppColors.primary),
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      minHeight: 7,
                      value: progress,
                      backgroundColor: AppColors.softAccent,
                      valueColor: AlwaysStoppedAnimation(
                        progress > 1.0
                            ? AppColors.error
                            : AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${(progress * 100).toStringAsFixed(0)}% dari target',
                    style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary),
                  ),
                ]),
          ),
        ]),
        const SizedBox(height: 16),
        const Divider(color: AppColors.border, height: 1),
        const SizedBox(height: 14),
        Row(children: [
          _macroChip('Protein', protein, const Color(0xFF2196F3)),
          _macroChip('Karbo', carbs, const Color(0xFFFF9800)),
          _macroChip('Lemak', fat, const Color(0xFFE91E63)),
        ]),
      ]),
    );
  }

  Widget _calorieRow(String label, double value, Color color) {
    return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary)),
          Text('${value.toStringAsFixed(0)} kcal',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: color)),
        ]);
  }

  Widget _macroChip(String label, double value, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(children: [
          Text(
            '${value.toStringAsFixed(1)}g',
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: color),
          ),
          const SizedBox(height: 3),
          Text(label,
              style: const TextStyle(
                  fontSize: 10, color: AppColors.textSecondary)),
        ]),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// STAT MINI CARD
// ════════════════════════════════════════════════════════════════
class _StatMiniCard extends StatelessWidget {
  const _StatMiniCard({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.sub,
    required this.progress,
  });

  final IconData icon;
  final Color color;
  final String label, value, sub;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(height: 10),
            Text(value,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: color)),
            Text(sub,
                style: const TextStyle(
                    fontSize: 10, color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                minHeight: 4,
                value: progress,
                backgroundColor: color.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
            const SizedBox(height: 5),
            Text(label,
                style: const TextStyle(
                    fontSize: 10, color: AppColors.textSecondary)),
          ]),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// INSIGHT BANNER
// ════════════════════════════════════════════════════════════════
class _InsightBanner extends StatelessWidget {
  const _InsightBanner({
    required this.totalCalories,
    required this.targetCalories,
    required this.totalWater,
    required this.targetWater,
    required this.sessions,
    required this.goal,
  });

  final double totalCalories, targetCalories;
  final int totalWater, targetWater, sessions;
  final String goal;

  String _buildInsight() {
    final calDiff = targetCalories - totalCalories;
    final waterDiff = targetWater - totalWater;

    if (totalCalories == 0 && totalWater == 0 && sessions == 0) {
      return '👋 Hari baru dimulai! Yuk catat makanan, minum air, dan mulai latihan.';
    }

    final parts = <String>[];

    if (calDiff > 300) {
      parts.add('Masih kurang ${calDiff.toStringAsFixed(0)} kcal dari target.');
    } else if (calDiff < -200) {
      parts.add('Kalori sudah melebihi target ${(-calDiff).toStringAsFixed(0)} kcal.');
    } else {
      parts.add('Kalori hari ini sudah mendekati target, bagus!');
    }

    if (waterDiff > 500) {
      parts.add('Tambah minum air, masih kurang ${waterDiff}ml.');
    } else {
      parts.add('Hidrasi hari ini sudah baik.');
    }

    if (sessions == 0) {
      parts.add('Belum ada sesi latihan hari ini.');
    } else {
      parts.add('$sessions sesi latihan sudah tercatat.');
    }

    return parts.join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.softAccent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.auto_awesome_rounded,
              color: AppColors.primary, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Ringkasan Hari Ini',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                Text(_buildInsight(),
                    style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textPrimary,
                        height: 1.5)),
              ]),
        ),
      ]),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// SECTION HEADER
// ════════════════════════════════════════════════════════════════
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.icon});
  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, color: AppColors.primary, size: 18),
      const SizedBox(width: 8),
      Text(title,
          style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary)),
    ]);
  }
}

// ════════════════════════════════════════════════════════════════
// LAST ACTIVITY CARD
// ════════════════════════════════════════════════════════════════
class _LastActivityCard extends StatelessWidget {
  const _LastActivityCard({this.outdoor, this.gym});
  final ActivityModel? outdoor;
  final WorkoutSessionModel? gym;

  @override
  Widget build(BuildContext context) {
    // Tentukan mana yang paling baru
    ActivityModel? showOutdoor;
    WorkoutSessionModel? showGym;

    if (outdoor != null && gym != null) {
      if (outdoor!.createdAt.compareTo(gym!.createdAt) >= 0) {
        showOutdoor = outdoor;
      } else {
        showGym = gym;
      }
    } else {
      showOutdoor = outdoor;
      showGym = gym;
    }

    if (showOutdoor != null) {
      return _OutdoorTile(activity: showOutdoor);
    }
    if (showGym != null) {
      return _GymTile(session: showGym);
    }
    return const SizedBox.shrink();
  }
}

class _OutdoorTile extends StatelessWidget {
  const _OutdoorTile({required this.activity});
  final ActivityModel activity;

  Color _color() {
    if (activity.activityType == 'Running') return const Color(0xFFE91E63);
    if (activity.activityType == 'Cycling') return const Color(0xFF2196F3);
    return AppColors.primary;
  }

  IconData _icon() {
    if (activity.activityType == 'Running') return Icons.directions_run;
    if (activity.activityType == 'Cycling') return Icons.directions_bike;
    return Icons.directions_walk;
  }

  @override
  Widget build(BuildContext context) {
    final color = _color();
    final date = DateTime.parse(activity.createdAt);
    final dur = activity.durationSeconds;
    final m = (dur % 3600) ~/ 60;
    final h = dur ~/ 3600;
    final durStr = h > 0 ? '${h}j ${m}m' : '${m}m';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14)),
          child: Icon(_icon(), color: color, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(activity.activityType,
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: color,
                        fontSize: 14)),
                const SizedBox(height: 3),
                Text(
                  '${activity.distanceKm.toStringAsFixed(2)} km  •  $durStr  •  '
                  '${activity.caloriesBurned.toStringAsFixed(0)} kcal',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
              ]),
        ),
        Text(
          DateFormat('HH:mm').format(date),
          style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.7),
              fontWeight: FontWeight.w600),
        ),
      ]),
    );
  }
}

class _GymTile extends StatelessWidget {
  const _GymTile({required this.session});
  final WorkoutSessionModel session;

  @override
  Widget build(BuildContext context) {
    const color = AppColors.primary;
    final date = DateTime.parse(session.createdAt);
    final dur = session.durationSeconds;
    final m = (dur % 3600) ~/ 60;
    final h = dur ~/ 3600;
    final durStr = h > 0 ? '${h}j ${m}m' : '${m}m';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14)),
          child: const Icon(Icons.fitness_center, color: color, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(session.programName,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: color,
                        fontSize: 14),
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
                Text(
                  '${session.totalSets} set  •  $durStr  •  '
                  '${session.caloriesBurned.toStringAsFixed(0)} kcal',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
              ]),
        ),
        Text(
          DateFormat('HH:mm').format(date),
          style: const TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600),
        ),
      ]),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// GAME CARD
// ════════════════════════════════════════════════════════════════
class _GameCard extends StatelessWidget {
  const _GameCard({required this.onPlay});
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A237E), Color(0xFF283593)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A237E).withOpacity(0.22),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(children: [
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text('MINI GAME',
                      style: TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1)),
                ),
                const SizedBox(height: 10),
                const Text('Fit Dash',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(
                  'Tangkap makanan sehat, hindari junk food!\nKumpulkan poin setinggi mungkin.',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.65),
                      fontSize: 12,
                      height: 1.5),
                ),
                const SizedBox(height: 14),
                GestureDetector(
                  onTap: onPlay,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.play_arrow_rounded,
                              color: Color(0xFF1A237E), size: 20),
                          SizedBox(width: 6),
                          Text('Main Sekarang',
                              style: TextStyle(
                                  color: Color(0xFF1A237E),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13)),
                        ]),
                  ),
                ),
              ]),
        ),
        const SizedBox(width: 12),
        const Text('🏃\n🍎\n🍔\n💨',
            style: TextStyle(fontSize: 28, height: 1.4)),
      ]),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// QUICK TIP
// ════════════════════════════════════════════════════════════════
class _QuickTip extends StatelessWidget {
  const _QuickTip({required this.goal});
  final String goal;

  static const _tips = {
    'Cutting': [
      '💡 Makan protein tinggi membantu menjaga massa otot saat defisit kalori.',
      '💡 Cardio pagi hari efektif membakar lemak saat perut kosong.',
      '💡 Tidur cukup 7-8 jam membantu regulasi hormon lapar.',
    ],
    'Bulking': [
      '💡 Makan setiap 3-4 jam membantu mencapai surplus kalori dengan mudah.',
      '💡 Latihan beban progresif adalah kunci pertumbuhan otot.',
      '💡 Protein 1.6-2.2 g/kg berat badan optimal untuk bulking.',
    ],
    'Maintain': [
      '💡 Konsistensi lebih penting dari intensitas. Latihan rutin setiap hari.',
      '💡 Hidrasi yang cukup meningkatkan performa dan fokus.',
      '💡 Variasikan menu makanan untuk memenuhi semua mikronutrien.',
    ],
  };

  @override
  Widget build(BuildContext context) {
    final tips = _tips[goal] ?? _tips['Maintain']!;
    final tip = tips[DateTime.now().day % tips.length];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.softCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('💡', style: TextStyle(fontSize: 20)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Tips Hari Ini',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                Text(
                  tip.replaceAll('💡 ', ''),
                  style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textPrimary,
                      height: 1.5),
                ),
              ]),
        ),
      ]),
    );
  }
}