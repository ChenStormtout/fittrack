import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../../data/models/game_score_model.dart';
import '../../../data/repositories/workout_repository.dart';

class FallingItem {
  int lane;
  double y;
  bool isHealthy;
  bool isLifeBonus;
  String emoji;
  bool isCollected;

  FallingItem({
    required this.lane,
    required this.y,
    required this.isHealthy,
    required this.isLifeBonus,
    required this.emoji,
    this.isCollected = false,
  });
}

class MinigameController extends ChangeNotifier {
  MinigameController({
    required WorkoutRepository workoutRepository,
  }) : _workoutRepository = workoutRepository;

  final WorkoutRepository _workoutRepository;
  final Random _random = Random();

  bool _isPlaying = false;
  bool _isCountingDown = false;
  int _countdownValue = 3;
  int _score = 0;
  int _bestScore = 0;
  int _timeLeft = 45;
  int _lives = 5;
  int _playerLane = 1;
  int _comboCount = 0;
  int _comboMultiplier = 1;
  String? _feedbackEmoji;
  bool _justHit = false;
  bool _scoreSaved = false;
  bool _isNewHighScore = false;

  // Disimpan saat startCountdown dipanggil
  String? _currentUserEmail;
  String? _currentPlayerName;

  // Difficulty scaling
  double _spawnInterval = 850;
  double _moveSpeed = 0.04;
  int _elapsedSeconds = 0;

  // Per-lane cooldown untuk cegah overlap
  final List<double> _laneLastSpawnY = [1.0, 1.0, 1.0];

  Timer? _gameTimer;
  Timer? _spawnTimer;
  Timer? _moveTimer;
  Timer? _countdownTimer;
  Timer? _feedbackTimer;

  final List<FallingItem> _items = [];
  List<GameScoreModel> _leaderboard = [];
  List<GameScoreModel> _myScores = [];

  bool get isPlaying => _isPlaying;
  bool get isCountingDown => _isCountingDown;
  int get countdownValue => _countdownValue;
  int get score => _score;
  int get bestScore => _bestScore;
  int get timeLeft => _timeLeft;
  int get lives => _lives;
  int get playerLane => _playerLane;
  int get comboCount => _comboCount;
  int get comboMultiplier => _comboMultiplier;
  String? get feedbackEmoji => _feedbackEmoji;
  bool get justHit => _justHit;
  bool get scoreSaved => _scoreSaved;
  bool get isNewHighScore => _isNewHighScore;
  List<FallingItem> get items => List.unmodifiable(_items);
  List<GameScoreModel> get leaderboard => _leaderboard;
  List<GameScoreModel> get myScores => _myScores;

  final List<String> healthyItems = ['🍎', '🥦', '💧', '🍌', '🥚'];
  final List<String> junkItems = ['🍔', '🍟', '🍩', '🥤'];

  void startCountdown({String? userEmail, String? playerName}) {
    _currentUserEmail = userEmail;
    _currentPlayerName = playerName;
    _isCountingDown = true;
    _countdownValue = 3;
    _scoreSaved = false;
    _isNewHighScore = false;
    notifyListeners();

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _countdownValue--;
      if (_countdownValue <= 0) {
        timer.cancel();
        _isCountingDown = false;
        _startGame();
      }
      notifyListeners();
    });
  }

  void _startGame() {
    _isPlaying = true;
    _score = 0;
    _timeLeft = 45;
    _lives = 5;
    _playerLane = 1;
    _comboCount = 0;
    _comboMultiplier = 1;
    _elapsedSeconds = 0;
    _spawnInterval = 850;
    _moveSpeed = 0.04;
    _feedbackEmoji = null;
    _justHit = false;
    _scoreSaved = false;
    _isNewHighScore = false;
    _items.clear();
    _laneLastSpawnY[0] = 1.0;
    _laneLastSpawnY[1] = 1.0;
    _laneLastSpawnY[2] = 1.0;

    _gameTimer?.cancel();
    _spawnTimer?.cancel();
    _moveTimer?.cancel();

    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _timeLeft--;
      _elapsedSeconds++;

      // Difficulty scaling setiap 10 detik
      if (_elapsedSeconds % 10 == 0) {
        _moveSpeed = (_moveSpeed + 0.008).clamp(0.04, 0.12);
        _spawnInterval = (_spawnInterval - 80).clamp(400, 850);
        _restartSpawnTimer();
      }

      if (_timeLeft <= 0 || _lives <= 0) {
        _finishGame();
      }
      notifyListeners();
    });

    _startSpawnTimer();

    _moveTimer = Timer.periodic(const Duration(milliseconds: 80), (_) {
      _moveItems();
    });

    notifyListeners();
  }

  // Untuk backward compatibility dengan UI lama
  void startGame({String? userEmail, String? playerName}) =>
      startCountdown(userEmail: userEmail, playerName: playerName);

  void _startSpawnTimer() {
    _spawnTimer?.cancel();
    _spawnTimer = Timer.periodic(
      Duration(milliseconds: _spawnInterval.toInt()),
      (_) => _spawnItem(),
    );
  }

  void _restartSpawnTimer() {
    _spawnTimer?.cancel();
    _startSpawnTimer();
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
    // Pilih lane yang tidak terlalu padat
    final availableLanes = <int>[];
    for (int i = 0; i < 3; i++) {
      // Cek apakah ada item di lane ini yang masih di atas 0.3
      final hasItemNearTop = _items.any((item) => item.lane == i && item.y < 0.3);
      if (!hasItemNearTop) availableLanes.add(i);
    }

    if (availableLanes.isEmpty) return;

    final lane = availableLanes[_random.nextInt(availableLanes.length)];
    final roll = _random.nextInt(100);

    if (roll < 8) {
      _items.add(FallingItem(
        lane: lane,
        y: 0,
        isHealthy: true,
        isLifeBonus: true,
        emoji: '❤️',
      ));
    } else {
      // Makin susah seiring waktu: junk food lebih sering
      final junkChance = (40 + (_elapsedSeconds * 0.5)).clamp(40.0, 55.0).toInt();
      final isHealthy = _random.nextInt(100) >= junkChance;
      final emoji = isHealthy
          ? healthyItems[_random.nextInt(healthyItems.length)]
          : junkItems[_random.nextInt(junkItems.length)];

      _items.add(FallingItem(
        lane: lane,
        y: 0,
        isHealthy: isHealthy,
        isLifeBonus: false,
        emoji: emoji,
      ));
    }

    notifyListeners();
  }

  void _moveItems() {
    if (!_isPlaying) return;

    for (final item in _items) {
      item.y += _moveSpeed;
    }

    final toRemove = <FallingItem>[];

    for (final item in _items) {
      if (item.isCollected) {
        toRemove.add(item);
        continue;
      }

      // Collision zone lebih presisi: 0.82 - 0.92
      if (item.y >= 0.82 && item.y <= 0.95 && item.lane == _playerLane) {
        item.isCollected = true;

        if (item.isLifeBonus) {
          _lives = (_lives + 1).clamp(0, 8);
          _score += 5;
          _showFeedback('❤️+1');
          _comboCount = 0;
          _comboMultiplier = 1;
        } else if (item.isHealthy) {
          _comboCount++;
          _comboMultiplier = (_comboCount ~/ 3 + 1).clamp(1, 5);
          final gained = 10 * _comboMultiplier;
          _score += gained;
          _showFeedback(_comboMultiplier > 1 ? '×$_comboMultiplier COMBO!' : '+$gained');
        } else {
          _score = (_score - 5).clamp(0, 99999);
          _lives -= 1;
          _comboCount = 0;
          _comboMultiplier = 1;
          _triggerHit();
          _showFeedback('💀 -5');
        }

        toRemove.add(item);
      } else if (item.y > 1.05) {
        if (item.isHealthy && !item.isLifeBonus) {
          _lives -= 1;
          _comboCount = 0;
          _comboMultiplier = 1;
          _triggerHit();
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

  void _showFeedback(String emoji) {
    _feedbackEmoji = emoji;
    _feedbackTimer?.cancel();
    _feedbackTimer = Timer(const Duration(milliseconds: 800), () {
      _feedbackEmoji = null;
      notifyListeners();
    });
  }

  void _triggerHit() {
    _justHit = true;
    Future.delayed(const Duration(milliseconds: 300), () {
      _justHit = false;
      notifyListeners();
    });
  }

  void _finishGame() {
    _gameTimer?.cancel();
    _spawnTimer?.cancel();
    _moveTimer?.cancel();
    _isPlaying = false;

    if (_score > _bestScore) {
      _bestScore = _score;
      _isNewHighScore = true;
    }

    notifyListeners();

    // Auto-save jika user login dan skor > 0
    if (_score > 0 && _currentUserEmail != null) {
      _autoSaveScore();
    }
  }

  Future<void> _autoSaveScore() async {
    final email = _currentUserEmail!;
    final name = (_currentPlayerName?.trim().isEmpty ?? true)
        ? 'Anonymous'
        : _currentPlayerName!.trim();

    // Cek apakah layak masuk top 10
    final currentLeaderboard = await _workoutRepository.getGameScores();
    final isTop10 = currentLeaderboard.length < 10 ||
        _score > (currentLeaderboard.last.score);

    if (!isTop10) {
      _scoreSaved = false;
      notifyListeners();
      return;
    }

    await _workoutRepository.insertGameScore(
      GameScoreModel(
        userEmail: email.trim().toLowerCase(),
        playerName: name,
        gameName: 'Fit Dash',
        score: _score,
        createdAt: DateTime.now().toIso8601String(),
      ),
    );

    _scoreSaved = true;
    await loadLeaderboard();
    await loadMyScores(email);
  }

  Future<void> loadLeaderboard() async {
    _leaderboard = await _workoutRepository.getGameScores();
    // Fix: jangan overwrite bestScore dari leaderboard global
    notifyListeners();
  }

  Future<void> loadMyScores(String userEmail) async {
    _myScores = await _workoutRepository.getGameScoresByUser(userEmail);
    // Ambil bestScore dari skor pribadi saja
    if (_myScores.isNotEmpty) {
      final personalBest = _myScores.map((s) => s.score).reduce(max);
      if (personalBest > _bestScore) {
        _bestScore = personalBest;
      }
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    _spawnTimer?.cancel();
    _moveTimer?.cancel();
    _countdownTimer?.cancel();
    _feedbackTimer?.cancel();
    super.dispose();
  }
}