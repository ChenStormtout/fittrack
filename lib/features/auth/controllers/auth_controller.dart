import 'package:flutter/foundation.dart';

import '../../../core/services/biometric_service.dart';
import '../../../core/services/secure_storage_service.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/auth_repository.dart';

class AuthController extends ChangeNotifier {
  AuthController({
    required SecureStorageService secureStorageService,
    required AuthRepository authRepository,
  }) : _secureStorageService = secureStorageService,
       _authRepository = authRepository;

  final SecureStorageService _secureStorageService;
  final AuthRepository _authRepository;
  final BiometricService _biometricService = BiometricService();

  bool _isLoggedIn = false;
  bool _isInitialized = false;
  bool _biometricEnabled = false;
  bool _hasSavedSession = false;

  String? _userEmail;
  String? _errorMessage;
  UserModel? _currentUser;

  bool get isLoggedIn => _isLoggedIn;
  bool get isInitialized => _isInitialized;
  bool get biometricEnabled => _biometricEnabled;
  bool get hasSavedSession => _hasSavedSession;
  bool get canUseBiometricLogin =>
      _biometricEnabled &&
      _hasSavedSession &&
      (_userEmail?.isNotEmpty ?? false);
  String? get userEmail => _userEmail;
  String? get errorMessage => _errorMessage;
  UserModel? get currentUser => _currentUser;

  void requireLoginOnLaunch() {
    _isLoggedIn = false;
    _currentUser = null;
    notifyListeners();
  }

  Future<void> initialize() async {
    final token = await _secureStorageService.getSessionToken();
    final email = await _secureStorageService.getSessionEmail();
    final biometric = await _secureStorageService.getBiometricEnabled();

    _hasSavedSession =
        token != null && token.isNotEmpty && email != null && email.isNotEmpty;
    _isLoggedIn = false;
    _userEmail = _hasSavedSession ? email : null;
    _biometricEnabled = biometric;

    if (_userEmail != null) {
      _currentUser = await _authRepository.getCurrentUser(_userEmail!);
    }

    _isInitialized = true;
    notifyListeners();
  }

  Future<bool> register({
    required String email,
    required String password,
  }) async {
    _errorMessage = null;

    try {
      final success = await _authRepository.register(
        email: email,
        password: password,
      );

      if (!success) {
        _errorMessage = 'Email sudah terdaftar';
        notifyListeners();
        return false;
      }

      return true;
    } catch (e) {
      _errorMessage = 'Error register: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> login({required String email, required String password}) async {
    _errorMessage = null;

    try {
      final success = await _authRepository.login(
        email: email,
        password: password,
      );

      if (!success) {
        _errorMessage = 'Email atau password salah';
        notifyListeners();
        return false;
      }

      final normalizedEmail = email.trim().toLowerCase();

      await _secureStorageService.saveSession(
        token: 'session_${DateTime.now().millisecondsSinceEpoch}',
        email: normalizedEmail,
      );

      _isLoggedIn = true;
      _hasSavedSession = true;
      _userEmail = normalizedEmail;
      _currentUser = await _authRepository.getCurrentUser(normalizedEmail);

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Error login: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> enableBiometric() async {
    final canUse = await _biometricService.canCheckBiometrics();
    if (!canUse) return false;

    final success = await _biometricService.authenticate();

    if (success) {
      _biometricEnabled = true;
      await _secureStorageService.setBiometricEnabled(true);
      notifyListeners();
    }

    return success;
  }

  Future<bool> loginWithBiometric() async {
    if (!canUseBiometricLogin || _userEmail == null) return false;

    final success = await _biometricService.authenticate();
    if (!success) return false;

    _isLoggedIn = true;
    _currentUser = await _authRepository.getCurrentUser(_userEmail!);
    notifyListeners();
    return true;
  }

  Future<bool> updateProfile({
    required String fullName,
    required int age,
    required String gender,
    required double heightCm,
    required double weightKg,
    required String goal,
    required String activityLevel,
  }) async {
    if (_userEmail == null) return false;

    try {
      final success = await _authRepository.updateProfile(
        email: _userEmail!,
        fullName: fullName,
        age: age,
        gender: gender,
        heightCm: heightCm,
        weightKg: weightKg,
        goal: goal,
        activityLevel: activityLevel,
      );

      if (success) {
        _currentUser = await _authRepository.getCurrentUser(_userEmail!);
        notifyListeners();
      }

      return success;
    } catch (e) {
      _errorMessage = 'Error update profile: $e';
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    final keepBiometricSession =
        _biometricEnabled && (_userEmail?.isNotEmpty ?? false);

    if (!keepBiometricSession) {
      await _secureStorageService.clearSession();
      await _secureStorageService.setBiometricEnabled(false);
      _hasSavedSession = false;
      _biometricEnabled = false;
      _userEmail = null;
    } else {
      _hasSavedSession = true;
    }

    _isLoggedIn = false;
    _currentUser = null;
    notifyListeners();
  }
}
