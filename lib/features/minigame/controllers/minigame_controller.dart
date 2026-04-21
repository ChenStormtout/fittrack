import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../../data/models/game_score_model.dart';
import '../../../data/repositories/workout_repository.dart';

class FallingItem {
  int lane;
  double y;
  bool isHealthy;
  String emoji;

  FallingItem({
    required this.lane,
    required this.y,
    required this.isHealthy,
    required this.emoji,
  });
}

class MinigameController extends ChangeNotifier {
  MinigameController({
    required WorkoutRepository workoutRepository,
  }) : _workoutRepository = workoutRepository;

  final WorkoutRepository _workoutRepository;
  final Random _random = Random();

  bool _isPlaying = false;
  int _score = 0;
  int _bestScore = 0;
  int _timeLeft = 45;
  int _lives = 3;
  int _playerLane = 1;

  Timer? _gameTimer;
  Timer? _spawnTimer;
  Timer? _moveTimer;

  final List<FallingItem> _items = [];
  List<GameScoreModel> _scores = [];

  bool get isPlaying => _isPlaying;
  int get score => _score;
  int get bestScore => _bestScore;
  int get timeLeft => _timeLeft;
  int get lives => _lives;
  int get playerLane => _playerLane;
  List<FallingItem> get items => List.unmodifiable(_items);
  List<GameScoreModel> get scores => _scores;

  final List<String> healthyItems = ['🍎', '🥦', '💧', '🍌', '🥚'];
  final List<String> junkItems = ['🍔', '🍟', '🍩', '🥤'];

  void startGame() {
    _isPlaying = true;
    _score = 0;
    _timeLeft = 45;
    _lives = 3;
    _playerLane = 1;
    _items.clear();

    _gameTimer?.cancel();
    _spawnTimer?.cancel();
    _moveTimer?.cancel();

    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _timeLeft--;
      if (_timeLeft <= 0 || _lives <= 0) {
        _finishGame();
      }
      notifyListeners();
    });

    _spawnTimer = Timer.periodic(const Duration(milliseconds: 850), (_) {
      _spawnItem();
    });

    _moveTimer = Timer.periodic(const Duration(milliseconds: 80), (_) {
      _moveItems();
    });

    notifyListeners();
  }

  void moveLeft() {
    if (!_isPlaying) return;
    if (_playerLane > 0) {
      _playerLane--;
      notifyListeners();
    }
  }

  void moveRight() {
    if (!_isPlaying) return;
    if (_playerLane < 2) {
      _playerLane++;
      notifyListeners();
    }
  }

  void _spawnItem() {
    final isHealthy = _random.nextBool();
    final emoji = isHealthy
        ? healthyItems[_random.nextInt(healthyItems.length)]
        : junkItems[_random.nextInt(junkItems.length)];

    _items.add(
      FallingItem(
        lane: _random.nextInt(3),
        y: 0,
        isHealthy: isHealthy,
        emoji: emoji,
      ),
    );

    notifyListeners();
  }

  void _moveItems() {
    if (!_isPlaying) return;

    for (final item in _items) {
      item.y += 0.04;
    }

    final toRemove = <FallingItem>[];

    for (final item in _items) {
      if (item.y >= 0.85 && item.lane == _playerLane) {
        if (item.isHealthy) {
          _score += 10;
        } else {
          _score = (_score - 5).clamp(0, 99999);
          _lives -= 1;
        }
        toRemove.add(item);
      } else if (item.y > 1.05) {
        if (item.isHealthy) {
          _lives -= 1;
        }
        toRemove.add(item);
      }
    }

    _items.removeWhere((item) => toRemove.contains(item));

    if (_lives <= 0) {
      _finishGame();
    }

    notifyListeners();
  }

  void _finishGame() {
    _gameTimer?.cancel();
    _spawnTimer?.cancel();
    _moveTimer?.cancel();
    _isPlaying = false;
    if (_score > _bestScore) {
      _bestScore = _score;
    }
    notifyListeners();
  }

  Future<void> saveScore(String userEmail) async {
    await _workoutRepository.insertGameScore(
      GameScoreModel(
        userEmail: userEmail.trim().toLowerCase(),
        gameName: 'Fit Dash',
        score: _score,
        createdAt: DateTime.now().toIso8601String(),
      ),
    );
    await loadScores(userEmail);
  }

  Future<void> loadScores(String userEmail) async {
    _scores = await _workoutRepository.getGameScores(userEmail);
    if (_scores.isNotEmpty) {
      _bestScore = _scores.first.score;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    _spawnTimer?.cancel();
    _moveTimer?.cancel();
    super.dispose();
  }
}