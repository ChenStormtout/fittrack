import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

class CryptoService {
  String generateSalt([int length = 16]) {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();

    return List.generate(
      length,
      (_) => chars[random.nextInt(chars.length)],
    ).join();
  }

  String hashPassword({required String password, required String salt}) {
    final bytes = utf8.encode('$password$salt');
    return sha256.convert(bytes).toString();
  }
}