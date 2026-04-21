import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../data/models/achievement_model.dart';
import '../../../data/models/workout_session_model.dart';
import '../../../data/repositories/workout_repository.dart';

class WorkoutExercise {
  final String name;
  final String description;
  final String youtubeUrl;
  final int sets;
  final int reps;
  final int restSeconds;
  final bool isTimed;

  WorkoutExercise({
    required this.name,
    required this.description,
    required this.youtubeUrl,
    required this.sets,
    required this.reps,
    required this.restSeconds,
    this.isTimed = false,
  });
}

class WorkoutProgram {
  final String category;
  final String title;
  final String subtitle;
  final String targetArea;
  final String difficulty;
  final int estimatedMinutes;
  final List<WorkoutExercise> exercises;

  WorkoutProgram({
    required this.category,
    required this.title,
    required this.subtitle,
    required this.targetArea,
    required this.difficulty,
    required this.estimatedMinutes,
    required this.exercises,
  });
}

class WorkoutController extends ChangeNotifier {
  WorkoutController({
    required WorkoutRepository workoutRepository,
  }) : _workoutRepository = workoutRepository;

  final WorkoutRepository _workoutRepository;

  WorkoutProgram? _currentProgram;
  int _currentExerciseIndex = 0;
  int _currentSet = 1;
  int _elapsedSeconds = 0;
  int _restRemaining = 0;
  bool _isWorkoutActive = false;
  bool _isResting = false;
  bool _isPaused = false;
  WorkoutSessionModel? _lastCompletedSession;

  Timer? _timer;
  Timer? _restTimer;

  List<WorkoutSessionModel> _history = [];
  List<AchievementModel> _achievements = [];

  WorkoutProgram? get currentProgram => _currentProgram;
  int get currentExerciseIndex => _currentExerciseIndex;
  int get currentSet => _currentSet;
  int get elapsedSeconds => _elapsedSeconds;
  int get restRemaining => _restRemaining;
  bool get isWorkoutActive => _isWorkoutActive;
  bool get isResting => _isResting;
  bool get isPaused => _isPaused;
  List<WorkoutSessionModel> get history => _history;
  List<AchievementModel> get achievements => _achievements;
  WorkoutSessionModel? get lastCompletedSession => _lastCompletedSession;

  WorkoutExercise? get currentExercise {
    if (_currentProgram == null) return null;
    if (_currentExerciseIndex >= _currentProgram!.exercises.length) return null;
    return _currentProgram!.exercises[_currentExerciseIndex];
  }

  int get totalExercises => _currentProgram?.exercises.length ?? 0;

  void startWorkout(WorkoutProgram program) {
    _currentProgram = program;
    _currentExerciseIndex = 0;
    _currentSet = 1;
    _elapsedSeconds = 0;
    _restRemaining = 0;
    _isWorkoutActive = true;
    _isResting = false;
    _isPaused = false;
    _lastCompletedSession = null;

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_isPaused && _isWorkoutActive) {
        _elapsedSeconds++;
        notifyListeners();
      }
    });

    notifyListeners();
  }

  void pauseWorkout() {
    _isPaused = !_isPaused;
    notifyListeners();
  }

  void finishCurrentSet() {
    final exercise = currentExercise;
    if (exercise == null) return;

    if (_currentSet < exercise.sets) {
      _startRest(exercise.restSeconds);
    } else {
      _moveToNextExerciseOrFinish();
    }
  }

  void _moveToNextExerciseOrFinish() {
    if (_currentProgram == null) return;

    if (_currentExerciseIndex < _currentProgram!.exercises.length - 1) {
      _currentExerciseIndex++;
      _currentSet = 1;
      _isResting = false;
      _restRemaining = 0;
    } else {
      _isWorkoutActive = false;
    }

    notifyListeners();
  }

  void _startRest(int seconds) {
    _isResting = true;
    _restRemaining = seconds;
    notifyListeners();

    _restTimer?.cancel();
    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isPaused) return;

      _restRemaining--;
      if (_restRemaining <= 0) {
        timer.cancel();
        _isResting = false;
        _restRemaining = 0;
        _currentSet++;
      }
      notifyListeners();
    });
  }

  void skipRest() {
    _restTimer?.cancel();
    _isResting = false;
    _restRemaining = 0;
    _currentSet++;
    notifyListeners();
  }

  Future<bool> completeWorkout(String userEmail) async {
    if (_currentProgram == null) return false;

    _timer?.cancel();
    _restTimer?.cancel();

    final totalSets = _currentProgram!.exercises.fold<int>(
      0,
      (sum, item) => sum + item.sets,
    );

    final calories = (_elapsedSeconds / 60.0) * 6.5;

    final session = WorkoutSessionModel(
      userEmail: userEmail.trim().toLowerCase(),
      category: _currentProgram!.category,
      programName: _currentProgram!.title,
      totalExercises: _currentProgram!.exercises.length,
      totalSets: totalSets,
      durationSeconds: _elapsedSeconds,
      caloriesBurned: calories,
      completed: 1,
      createdAt: DateTime.now().toIso8601String(),
    );

    await _workoutRepository.insertWorkoutSession(session);

    if (_elapsedSeconds >= 600) {
      await _workoutRepository.insertAchievement(
        AchievementModel(
          userEmail: userEmail.trim().toLowerCase(),
          title: 'Workout Completed',
          description: 'Berhasil menyelesaikan ${_currentProgram!.title}',
          createdAt: DateTime.now().toIso8601String(),
        ),
      );
    }

    await loadHistory(userEmail);
    await loadAchievements(userEmail);

    _lastCompletedSession = session;
    _clearSession(clearResult: false);
    return true;
  }

  void cancelWorkout() {
    _clearSession(clearResult: true);
  }

  void clearLastResult() {
    _lastCompletedSession = null;
    notifyListeners();
  }

  void _clearSession({required bool clearResult}) {
    _timer?.cancel();
    _restTimer?.cancel();
    _currentProgram = null;
    _currentExerciseIndex = 0;
    _currentSet = 1;
    _elapsedSeconds = 0;
    _restRemaining = 0;
    _isWorkoutActive = false;
    _isResting = false;
    _isPaused = false;
    if (clearResult) {
      _lastCompletedSession = null;
    }
    notifyListeners();
  }

  Future<void> loadHistory(String userEmail) async {
    _history = await _workoutRepository.getWorkoutHistory(userEmail);
    notifyListeners();
  }

  Future<void> loadAchievements(String userEmail) async {
    _achievements = await _workoutRepository.getAchievements(userEmail);
    notifyListeners();
  }

  List<WorkoutProgram> getWorkoutPrograms() {
    return [
      WorkoutProgram(
        category: 'Calisthenics',
        title: 'Calisthenics Upper Body Beginner',
        subtitle: 'Bodyweight dasar untuk dada, bahu, dan core',
        targetArea: 'Upper Body',
        difficulty: 'Beginner',
        estimatedMinutes: 18,
        exercises: [
          WorkoutExercise(
            name: 'Incline Push-up',
            description: 'Push-up di permukaan lebih tinggi agar lebih mudah.',
            youtubeUrl: 'https://www.youtube.com/results?search_query=incline+push+up+tutorial',
            sets: 3,
            reps: 10,
            restSeconds: 40,
          ),
          WorkoutExercise(
            name: 'Knee Push-up',
            description: 'Push-up dengan lutut menyentuh lantai.',
            youtubeUrl: 'https://www.youtube.com/results?search_query=knee+push+up+tutorial',
            sets: 3,
            reps: 8,
            restSeconds: 45,
          ),
          WorkoutExercise(
            name: 'Plank',
            description: 'Tahan posisi tubuh lurus untuk melatih core.',
            youtubeUrl: 'https://www.youtube.com/results?search_query=plank+tutorial',
            sets: 3,
            reps: 30,
            restSeconds: 30,
            isTimed: true,
          ),
        ],
      ),
      WorkoutProgram(
        category: 'Calisthenics',
        title: 'Calisthenics Lower Body Advance',
        subtitle: 'Kaki dan core dengan intensitas lebih tinggi',
        targetArea: 'Lower Body',
        difficulty: 'Advance',
        estimatedMinutes: 24,
        exercises: [
          WorkoutExercise(
            name: 'Jump Squat',
            description: 'Squat eksplosif untuk power kaki.',
            youtubeUrl: 'https://www.youtube.com/results?search_query=jump+squat+tutorial',
            sets: 4,
            reps: 15,
            restSeconds: 40,
          ),
          WorkoutExercise(
            name: 'Bulgarian Split Squat',
            description: 'Latihan unilateral untuk paha dan glute.',
            youtubeUrl: 'https://www.youtube.com/results?search_query=bulgarian+split+squat+tutorial',
            sets: 4,
            reps: 10,
            restSeconds: 45,
          ),
          WorkoutExercise(
            name: 'Wall Sit',
            description: 'Isometrik untuk daya tahan otot kaki.',
            youtubeUrl: 'https://www.youtube.com/results?search_query=wall+sit+tutorial',
            sets: 3,
            reps: 45,
            restSeconds: 30,
            isTimed: true,
          ),
        ],
      ),
      WorkoutProgram(
        category: 'Free Weight',
        title: 'Free Weight Chest & Tricep',
        subtitle: 'Push day sederhana untuk dada dan trisep',
        targetArea: 'Push',
        difficulty: 'Intermediate',
        estimatedMinutes: 26,
        exercises: [
          WorkoutExercise(
            name: 'Dumbbell Press',
            description: 'Tekan dumbbell ke atas untuk melatih dada.',
            youtubeUrl: 'https://www.youtube.com/results?search_query=dumbbell+press+tutorial',
            sets: 4,
            reps: 12,
            restSeconds: 50,
          ),
          WorkoutExercise(
            name: 'Incline Dumbbell Press',
            description: 'Fokus upper chest.',
            youtubeUrl: 'https://www.youtube.com/results?search_query=incline+dumbbell+press+tutorial',
            sets: 3,
            reps: 10,
            restSeconds: 45,
          ),
          WorkoutExercise(
            name: 'Tricep Extension',
            description: 'Latihan trisep dengan dumbbell.',
            youtubeUrl: 'https://www.youtube.com/results?search_query=tricep+extension+tutorial',
            sets: 3,
            reps: 12,
            restSeconds: 40,
          ),
        ],
      ),
      WorkoutProgram(
        category: 'Free Weight',
        title: 'Free Weight Back & Bicep',
        subtitle: 'Pull day untuk punggung dan lengan',
        targetArea: 'Pull',
        difficulty: 'Intermediate',
        estimatedMinutes: 24,
        exercises: [
          WorkoutExercise(
            name: 'Dumbbell Row',
            description: 'Melatih punggung atas dan lats.',
            youtubeUrl: 'https://www.youtube.com/results?search_query=dumbbell+row+tutorial',
            sets: 4,
            reps: 10,
            restSeconds: 45,
          ),
          WorkoutExercise(
            name: 'Bicep Curl',
            description: 'Latihan dasar untuk bisep.',
            youtubeUrl: 'https://www.youtube.com/results?search_query=bicep+curl+tutorial',
            sets: 4,
            reps: 12,
            restSeconds: 35,
          ),
          WorkoutExercise(
            name: 'Hammer Curl',
            description: 'Variasi curl untuk bisep dan lengan bawah.',
            youtubeUrl: 'https://www.youtube.com/results?search_query=hammer+curl+tutorial',
            sets: 3,
            reps: 12,
            restSeconds: 35,
          ),
        ],
      ),
      WorkoutProgram(
        category: 'Mobility',
        title: 'Mobility Full Body Recovery',
        subtitle: 'Stretching dan recovery untuk seluruh tubuh',
        targetArea: 'Recovery',
        difficulty: 'All Levels',
        estimatedMinutes: 12,
        exercises: [
          WorkoutExercise(
            name: 'Hamstring Stretch',
            description: 'Stretch paha belakang.',
            youtubeUrl: 'https://www.youtube.com/results?search_query=hamstring+stretch+tutorial',
            sets: 3,
            reps: 30,
            restSeconds: 20,
            isTimed: true,
          ),
          WorkoutExercise(
            name: 'Hip Opener',
            description: 'Membuka pinggul dan fleksibilitas.',
            youtubeUrl: 'https://www.youtube.com/results?search_query=hip+opener+stretch+tutorial',
            sets: 3,
            reps: 30,
            restSeconds: 20,
            isTimed: true,
          ),
          WorkoutExercise(
            name: 'Shoulder Stretch',
            description: 'Membantu recovery bahu dan dada.',
            youtubeUrl: 'https://www.youtube.com/results?search_query=shoulder+stretch+tutorial',
            sets: 3,
            reps: 30,
            restSeconds: 20,
            isTimed: true,
          ),
        ],
      ),
    ];
  }

  @override
  void dispose() {
    _timer?.cancel();
    _restTimer?.cancel();
    super.dispose();
  }
}