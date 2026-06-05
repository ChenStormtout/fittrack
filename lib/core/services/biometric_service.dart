import 'package:local_auth/local_auth.dart';

class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();

  Future<bool> canCheckBiometrics() async {
    try {
      final isSupported = await _auth.isDeviceSupported();
      return isSupported;
    } catch (e) {
      return false;
    }
  }

  Future<bool> authenticate({
    String localizedReason = 'Verifikasi identitas untuk login',
    bool sensitiveTransaction = false,
  }) async {
    try {
      final isSupported = await _auth.isDeviceSupported();
      if (!isSupported) return false;

      return await _auth.authenticate(
        localizedReason: localizedReason,
        options: AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
          sensitiveTransaction: sensitiveTransaction,
        ),
      );
    } catch (e) {
      print('Biometric error: $e');
      return false;
    }
  }
}
