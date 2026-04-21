import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../auth/controllers/auth_controller.dart';
import 'controllers/minigame_controller.dart';

class MinigamePage extends StatefulWidget {
  const MinigamePage({super.key});

  @override
  State<MinigamePage> createState() => _MinigamePageState();
}

class _MinigamePageState extends State<MinigamePage> {
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    _loaded = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userEmail = context.read<AuthController>().userEmail;
      if (userEmail != null) {
        context.read<MinigameController>().loadScores(userEmail);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final gameController = context.watch<MinigameController>();
    final authController = context.watch<AuthController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Fit Dash')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
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
                _topInfo('Lives', '${gameController.lives}'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 420,
            decoration: BoxDecoration(
              color: AppColors.softCard,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: AppColors.border),
            ),
            child: Stack(
              children: [
                Row(
                  children: List.generate(3, (index) {
                    return Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border(
                            right: BorderSide(
                              color: index == 2 ? Colors.transparent : AppColors.border,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                ...gameController.items.map((item) {
                  return Positioned(
                    top: item.y * 360,
                    left: item.lane * ((MediaQuery.of(context).size.width - 32) / 3) + 40,
                    child: Text(
                      item.emoji,
                      style: const TextStyle(fontSize: 34),
                    ),
                  );
                }),
                Positioned(
                  bottom: 18,
                  left: gameController.playerLane * ((MediaQuery.of(context).size.width - 32) / 3) + 30,
                  child: const Text(
                    '🏃',
                    style: TextStyle(fontSize: 46),
                  ),
                ),
                if (!gameController.isPlaying)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: Center(
                        child: ElevatedButton(
                          onPressed: gameController.startGame,
                          child: const Text('Start Game'),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: gameController.isPlaying ? gameController.moveLeft : null,
                  icon: const Icon(Icons.arrow_left),
                  label: const Text('Kiri'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: gameController.isPlaying ? gameController.moveRight : null,
                  icon: const Icon(Icons.arrow_right),
                  label: const Text('Kanan'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (!gameController.isPlaying && gameController.score > 0)
            ElevatedButton(
              onPressed: () async {
                if (authController.userEmail != null) {
                  await gameController.saveScore(authController.userEmail!);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('High score disimpan')),
                  );
                }
              },
              child: const Text('Simpan Score'),
            ),
          const SizedBox(height: 18),
          const Text(
            'High Score',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          if (gameController.scores.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: const [
                    Icon(Icons.sports_esports_outlined, size: 36, color: AppColors.textSecondary),
                    SizedBox(height: 8),
                    Text('Belum ada high score'),
                  ],
                ),
              ),
            )
          else
            ...gameController.scores.take(10).map((score) {
              return Card(
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.softCard,
                    child: Icon(Icons.emoji_events, color: AppColors.primary),
                  ),
                  title: Text(score.gameName),
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

  Widget _topInfo(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 22,
          ),
        ),
      ],
    );
  }
}