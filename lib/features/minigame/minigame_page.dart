import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../auth/controllers/auth_controller.dart';
import 'controllers/minigame_controller.dart';

class MinigamePage extends StatefulWidget {
  const MinigamePage({super.key});

  @override
  State<MinigamePage> createState() => _MinigamePageState();
}

class _MinigamePageState extends State<MinigamePage>
    with SingleTickerProviderStateMixin {
  bool _loaded = false;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  double _swipeStartX = 0;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 8).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    _loaded = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthController>();
      final game = context.read<MinigameController>();

      game.loadLeaderboard();
      if (auth.userEmail != null) {
        game.loadMyScores(auth.userEmail!);
      }
    });
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _triggerShake() {
    _shakeController.forward(from: 0);
    HapticFeedback.mediumImpact();
  }

  @override
  Widget build(BuildContext context) {
    final gameController = context.watch<MinigameController>();
    final authController = context.watch<AuthController>();

    // Trigger shake saat kena hit
    if (gameController.justHit) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _triggerShake());
    }

    final playerName =
        authController.currentUser?.fullName?.trim().isNotEmpty == true
            ? authController.currentUser!.fullName!.trim()
            : (authController.userEmail ?? 'Anonymous');

    return Scaffold(
      appBar: AppBar(title: const Text('Fit Dash')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          // ── Header stats ──
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryLight],
              ),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _topInfo('Score', '${gameController.score}'),
                _topInfo('Best', '${gameController.bestScore}'),
                _topInfo('Lives', _livesDisplay(gameController.lives)),
                _topInfo('Time', '${gameController.timeLeft}s'),
              ],
            ),
          ),

          // ── Combo indicator ──
          if (gameController.comboMultiplier > 1)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.orange),
                  ),
                  child: Text(
                    '🔥 COMBO ×${gameController.comboMultiplier}  (${gameController.comboCount} beruntun)',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Colors.orange.shade800,
                    ),
                  ),
                ),
              ),
            ),

          const SizedBox(height: 12),

          // ── Game arena ──
          AnimatedBuilder(
            animation: _shakeAnimation,
            builder: (context, child) {
              final shake = _shakeController.isAnimating
                  ? (_shakeAnimation.value *
                      ((_shakeController.value * 10).floor().isEven ? 1 : -1))
                  : 0.0;
              return Transform.translate(
                offset: Offset(shake, 0),
                child: child,
              );
            },
            child: GestureDetector(
              onHorizontalDragStart: (details) {
                _swipeStartX = details.globalPosition.dx;
              },
              onHorizontalDragEnd: (details) {
                final diff = details.globalPosition.dx - _swipeStartX;
                if (diff < -30) {
                  gameController.moveLeft();
                } else if (diff > 30) {
                  gameController.moveRight();
                }
              },
              child: Container(
                height: 420,
                decoration: BoxDecoration(
                  color: AppColors.softCard,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: gameController.justHit
                        ? Colors.red
                        : AppColors.border,
                    width: gameController.justHit ? 2.5 : 1,
                  ),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final laneWidth = constraints.maxWidth / 3;

                    return Stack(
                      clipBehavior: Clip.hardEdge,
                      children: [
                        // Lane dividers
                        Row(
                          children: List.generate(3, (index) {
                            return Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border(
                                    right: BorderSide(
                                      color: index == 2
                                          ? Colors.transparent
                                          : AppColors.border,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),

                        // Falling items
                        ...gameController.items.map((item) {
                          return Positioned(
                            top: item.y * 360,
                            left: item.lane * laneWidth +
                                (laneWidth / 2) -
                                18,
                            child: Text(
                              item.emoji,
                              style: const TextStyle(fontSize: 34),
                            ),
                          );
                        }),

                        // Player
                        AnimatedPositioned(
                          duration: const Duration(milliseconds: 80),
                          bottom: 18,
                          left: gameController.playerLane * laneWidth +
                              (laneWidth / 2) -
                              22,
                          child: const Text(
                            '🏃',
                            style: TextStyle(fontSize: 46),
                          ),
                        ),

                        // Feedback popup
                        if (gameController.feedbackEmoji != null)
                          Positioned(
                            top: 16,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.65),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  gameController.feedbackEmoji!,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                          ),

                        // Countdown overlay
                        if (gameController.isCountingDown)
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(28),
                              ),
                              child: Center(
                                child: Text(
                                  gameController.countdownValue > 0
                                      ? '${gameController.countdownValue}'
                                      : 'GO!',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 80,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ),
                          ),

                        // Start / Game Over overlay
                        if (!gameController.isPlaying &&
                            !gameController.isCountingDown)
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(28),
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (gameController.score > 0) ...[
                                      if (gameController.isNewHighScore)
                                        const Text(
                                          '🏆 NEW HIGH SCORE!',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w900,
                                            color: Colors.amber,
                                          ),
                                        ),
                                      Text(
                                        gameController.isNewHighScore
                                            ? 'GAME OVER'
                                            : 'GAME OVER',
                                        style: const TextStyle(
                                          fontSize: 26,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Skor: ${gameController.score}',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          color: Colors.white70,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                    ],
                                    ElevatedButton(
                                      onPressed: () => gameController.startGame(
                                        userEmail: authController.userEmail,
                                        playerName: playerName,
                                      ),
                                      child: Text(gameController.score > 0
                                          ? 'Main Lagi'
                                          : 'Start Game'),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ── Controls ──
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed:
                      gameController.isPlaying ? gameController.moveLeft : null,
                  icon: const Icon(Icons.arrow_left),
                  label: const Text('Kiri'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: gameController.isPlaying
                      ? gameController.moveRight
                      : null,
                  icon: const Icon(Icons.arrow_right),
                  label: const Text('Kanan'),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ── Rules card ──
          Card(
            color: AppColors.softAccent,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: const [
                  Text(
                    'Aturan Game',
                    style:
                        TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Ambil item sehat untuk tambah score. Combo berturut-turut melipatgandakan poin. '
                    'Hindari junk food. Bonus ❤️ menambah nyawa. '
                    'Jika item sehat terlewat, nyawa berkurang. Game makin cepat seiring waktu!',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ── Auto-save status ──
          if (!gameController.isPlaying && gameController.score > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Center(
                child: gameController.scoreSaved
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle,
                              color: Colors.green.shade600, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            gameController.isNewHighScore
                                ? '🏆 New High Score! Tersimpan ke leaderboard'
                                : '✅ Score tersimpan ke leaderboard',
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.info_outline,
                              color: Colors.grey, size: 18),
                          SizedBox(width: 6),
                          Text(
                            'Skor tidak masuk top 10',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
              ),
            ),

          const SizedBox(height: 22),

          // ── Leaderboard ──
          const Text(
            'Leaderboard',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          if (gameController.leaderboard.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: const [
                    Icon(Icons.leaderboard_outlined,
                        size: 36, color: AppColors.textSecondary),
                    SizedBox(height: 8),
                    Text('Belum ada leaderboard'),
                  ],
                ),
              ),
            )
          else
            ...gameController.leaderboard
                .take(10)
                .toList()
                .asMap()
                .entries
                .map((entry) {
              final index = entry.key;
              final score = entry.value;
              final medal = index == 0
                  ? '🥇'
                  : index == 1
                      ? '🥈'
                      : index == 2
                          ? '🥉'
                          : '${index + 1}';

              return Card(
                child: ListTile(
                  leading: index < 3
                      ? Text(medal, style: const TextStyle(fontSize: 24))
                      : CircleAvatar(
                          backgroundColor: AppColors.softCard,
                          child: Text('$medal'),
                        ),
                  title: Text(
                    score.playerName.isEmpty ? 'Anonymous' : score.playerName,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(score.createdAt.substring(0, 10)),
                  trailing: Text(
                    '${score.score}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                ),
              );
            }),

          const SizedBox(height: 22),

          // ── My scores ──
          const Text(
            'Skor Saya',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          if (gameController.myScores.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: const [
                    Icon(Icons.sports_esports_outlined,
                        size: 36, color: AppColors.textSecondary),
                    SizedBox(height: 8),
                    Text('Belum ada skor pribadi'),
                  ],
                ),
              ),
            )
          else
            ...gameController.myScores.take(5).map((score) {
              return Card(
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.softCard,
                    child: Icon(Icons.person, color: AppColors.primary),
                  ),
                  title: Text(score.playerName),
                  subtitle: Text(score.createdAt.substring(0, 10)),
                  trailing: Text(
                    '${score.score}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  String _livesDisplay(int lives) {
    if (lives <= 0) return '💀';
    return '❤️' * lives.clamp(0, 5);
  }

  Widget _topInfo(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
      ],
    );
  }
}