import 'dart:convert';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// Hachage PBKDF2-HMAC-SHA256 des secrets (mots de passe, réponses de
/// sécurité). Format stocké : `pbkdf2_sha256$<itérations>$<sel b64>$<clé b64>`.
///
/// Le calcul tourne dans un isolate (Isolate.run) : l'interface ne se fige
/// plus pendant la connexion, ce qui permet aussi d'augmenter le nombre
/// d'itérations. Les anciens hachages (10 000 itérations) restent vérifiables
/// puisque le nombre d'itérations est lu dans la valeur stockée.
class PasswordHasher {
  PasswordHasher._();

  static const int iterations = 40000;
  static const int _saltLength = 16;
  static const int _keyLength = 32;

  static Future<String> hash(String secret) {
    final salt = _randomBytes(_saltLength);
    return Isolate.run(() => _encode(secret, salt, iterations));
  }

  static Future<bool> verify(String secret, String stored) {
    return Isolate.run(() => verifySync(secret, stored));
  }

  /// Version synchrone, exposée pour les tests et les isolates.
  static bool verifySync(String secret, String stored) {
    try {
      final parts = stored.split(r'$');
      if (parts.length != 4 || parts[0] != 'pbkdf2_sha256') return false;
      final rounds = int.parse(parts[1]);
      final salt = base64Decode(parts[2]);
      final expected = base64Decode(parts[3]);
      final actual = pbkdf2(utf8.encode(secret), salt, rounds, expected.length);
      return _constantTimeEquals(actual, expected);
    } catch (_) {
      return false;
    }
  }

  /// Version synchrone du hachage, exposée pour les tests.
  static String hashSync(String secret, {int rounds = iterations}) {
    return _encode(secret, _randomBytes(_saltLength), rounds);
  }

  static String _encode(String secret, List<int> salt, int rounds) {
    final key = pbkdf2(utf8.encode(secret), salt, rounds, _keyLength);
    return 'pbkdf2_sha256\$$rounds\$${base64Encode(salt)}\$${base64Encode(key)}';
  }

  static Uint8List pbkdf2(List<int> password, List<int> salt, int rounds, int keyLength) {
    final hmac = Hmac(sha256, password);
    const hLen = 32;
    final blocks = (keyLength + hLen - 1) ~/ hLen;
    final out = BytesBuilder(copy: false);
    for (var i = 1; i <= blocks; i++) {
      final blockIndex = [(i >> 24) & 0xff, (i >> 16) & 0xff, (i >> 8) & 0xff, i & 0xff];
      var u = hmac.convert([...salt, ...blockIndex]).bytes;
      final t = Uint8List.fromList(u);
      for (var j = 1; j < rounds; j++) {
        u = hmac.convert(u).bytes;
        for (var k = 0; k < t.length; k++) {
          t[k] ^= u[k];
        }
      }
      out.add(t);
    }
    return Uint8List.fromList(out.takeBytes().sublist(0, keyLength));
  }

  static List<int> _randomBytes(int length) {
    final rnd = Random.secure();
    return List<int>.generate(length, (_) => rnd.nextInt(256));
  }

  static bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }
}

/// Normalisation d'une réponse de sécurité ou d'un nom complet avant
/// comparaison : casse, accents, ponctuation et espaces multiples ignorés,
/// pour que « Maïs », « mais » et « MAIS » soient la même réponse.
String normalizeSecret(String input) {
  const accents = {
    'à': 'a', 'á': 'a', 'â': 'a', 'ä': 'a', 'ã': 'a', 'å': 'a',
    'è': 'e', 'é': 'e', 'ê': 'e', 'ë': 'e',
    'ì': 'i', 'í': 'i', 'î': 'i', 'ï': 'i',
    'ò': 'o', 'ó': 'o', 'ô': 'o', 'ö': 'o', 'õ': 'o',
    'ù': 'u', 'ú': 'u', 'û': 'u', 'ü': 'u',
    'ç': 'c', 'ñ': 'n', 'ÿ': 'y', 'œ': 'oe', 'æ': 'ae',
  };
  var s = input.toLowerCase().trim();
  accents.forEach((k, v) => s = s.replaceAll(k, v));
  s = s.replaceAll(RegExp(r"[^a-z0-9 ]"), ' ');
  return s.replaceAll(RegExp(r'\s+'), ' ').trim();
}
