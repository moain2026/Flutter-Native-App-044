// ============================================================
// YECO - تجزئة كلمات المرور (لا تُخزَّن كلمة المرور نصاً في SQLite)
// الصيغة: pbkdf2$iterations$saltHex$hashHex
// ============================================================

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

abstract final class PasswordHasher {
  static const _iterations = 12000;
  static final _rng = Random.secure();

  static String hash(String password, {String? saltHex}) {
    final salt = saltHex ?? _randomHex(16);
    final derived = _pbkdf2(password, salt, _iterations);
    return 'pbkdf2\$$_iterations\$$salt\$$derived';
  }

  static bool verify(String password, String stored) {
    final parts = stored.split('\$');
    if (parts.length != 4 || parts[0] != 'pbkdf2') return false;
    final iterations = int.tryParse(parts[1]) ?? _iterations;
    final derived = _pbkdf2(password, parts[2], iterations);
    return _constEq(derived, parts[3]);
  }

  static String _pbkdf2(String password, String saltHex, int iterations) {
    final hmac = Hmac(sha256, utf8.encode(password));
    final salt = _fromHex(saltHex);
    final block = Uint8List.fromList([...salt, 0, 0, 0, 1]);
    var u = Uint8List.fromList(hmac.convert(block).bytes);
    final out = Uint8List.fromList(u);
    for (var i = 1; i < iterations; i++) {
      u = Uint8List.fromList(hmac.convert(u).bytes);
      for (var j = 0; j < out.length; j++) {
        out[j] ^= u[j];
      }
    }
    return out.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  static String _randomHex(int bytes) => List.generate(
    bytes,
    (_) => _rng.nextInt(256),
  ).map((b) => b.toRadixString(16).padLeft(2, '0')).join();

  static Uint8List _fromHex(String hex) {
    final out = Uint8List(hex.length ~/ 2);
    for (var i = 0; i < out.length; i++) {
      out[i] = int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16);
    }
    return out;
  }

  static bool _constEq(String a, String b) {
    if (a.length != b.length) return false;
    var d = 0;
    for (var i = 0; i < a.length; i++) {
      d |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return d == 0;
  }
}
