import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const _storage = FlutterSecureStorage();

  static const _sessionKey = 'session_token';
  static const _emailKey = 'session_email';
  static const _biometricKey = 'biometric_enabled';

  Future<void> saveSession({
    required String token,
    required String email,
  }) async {
    await _storage.write(key: _sessionKey, value: token);
    await _storage.write(key: _emailKey, value: email);
  }

  Future<String?> getSessionToken() async {
    return _storage.read(key: _sessionKey);
  }

  Future<String?> getSessionEmail() async {
    return _storage.read(key: _emailKey);
  }

  // Hanya hapus token, email tetap untuk biometric
  Future<void> clearSession() async {
    await _storage.delete(key: _sessionKey);
  }

  Future<void> setBiometricEnabled(bool value) async {
    await _storage.write(key: _biometricKey, value: value.toString());
  }

  Future<bool> getBiometricEnabled() async {
    final value = await _storage.read(key: _biometricKey);
    return value == 'true';
  }

  Future<void> clearBiometric() async {
    await _storage.delete(key: _biometricKey);
  }

  Future<void> clearAllAuthData() async {
    await _storage.delete(key: _sessionKey);
    await _storage.delete(key: _emailKey);
    await _storage.delete(key: _biometricKey);
  }
}