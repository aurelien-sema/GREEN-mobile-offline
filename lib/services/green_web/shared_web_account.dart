import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'green_web_client.dart';

/// Identifiants du compte GREEN Web par défaut (assets/.env, non versionné).
class SharedAccountCredentials {
  final String identifier;
  final String? fallbackIdentifier;
  final String password;

  const SharedAccountCredentials({required this.identifier, this.fallbackIdentifier, required this.password});

  /// GREEN_WEB_EMAIL (ou GREEN_WEB_PHONE) + GREEN_WEB_PASSWORD. null si
  /// absents : l'envoi reste alors en file, sans perte.
  static SharedAccountCredentials? fromEnv([Map<String, String>? env]) {
    String? get(String k) {
      String? v;
      try {
        v = env != null ? env[k] : dotenv.maybeGet(k);
      } catch (_) {}
      v = v?.trim();
      return v == null || v.isEmpty ? null : v;
    }

    final email = get('GREEN_WEB_EMAIL');
    final phone = get('GREEN_WEB_PHONE');
    final password = get('GREEN_WEB_PASSWORD');
    final id = email ?? phone;
    if (id == null || password == null) return null;
    return SharedAccountCredentials(
      identifier: id,
      fallbackIdentifier: email != null && phone != null ? phone : null,
      password: password,
    );
  }
}

/// Erreur d'ouverture du compte partagé.
class SharedAccountException implements Exception {
  /// not-configured | rejected (identifiants refusés) | disabled (compte
  /// désactivé côté web).
  final String code;
  const SharedAccountException(this.code);
  @override
  String toString() => 'SharedAccountException($code)';
}

/// Compte GREEN Web unique utilisé par tous les comptes de l'application
/// pour envoyer les photos et analyses au serveur.
///
/// - Le mot de passe n'est jamais écrit sur le téléphone : seul le jeton
///   JWT (valable 7 jours) est conservé, dans le stockage chiffré d'Android
///   (EncryptedSharedPreferences, clé maître dans le Keystore).
/// - Le jeton est renouvelé 12 h avant son expiration, ou dès que le serveur
///   le refuse (401).
/// - Après un refus des identifiants, aucune nouvelle tentative pendant
///   1 h : pas de rafale de connexions refusées vers le serveur.
class SharedWebAccount {
  static const tokenKey = 'greenweb_shared_token';
  static const _renewBefore = Duration(hours: 12);
  static const _rejectCooldown = Duration(hours: 1);

  final GreenWebClient client;
  final FlutterSecureStorage _secure;
  final SharedAccountCredentials? Function() _credentials;
  final DateTime Function() _now;

  String? _token;
  DateTime? _rejectedAt;
  Future<String>? _opening;

  SharedWebAccount({
    required this.client,
    FlutterSecureStorage? secure,
    SharedAccountCredentials? Function()? credentials,
    DateTime Function()? clock,
  })  : _secure = secure ?? const FlutterSecureStorage(),
        _credentials = credentials ?? SharedAccountCredentials.fromEnv,
        _now = clock ?? DateTime.now;

  bool get isConfigured => _credentials() != null;

  /// Jeton valide, ouvert ou renouvelé si nécessaire. Lève
  /// [SharedAccountException] ou une erreur réseau.
  Future<String> token() async {
    final cached = _token ?? await _read();
    if (cached != null && !_expiresSoon(cached)) return _token = cached;
    return _opening ??= _login().whenComplete(() => _opening = null);
  }

  /// Le serveur a refusé le jeton : il sera rouvert au prochain envoi.
  Future<void> invalidate() async {
    _token = null;
    try {
      await _secure.delete(key: tokenKey);
    } catch (_) {}
  }

  Future<String> _login() async {
    final creds = _credentials();
    if (creds == null) throw const SharedAccountException('not-configured');
    final rejected = _rejectedAt;
    if (rejected != null && _now().difference(rejected) < _rejectCooldown) {
      throw const SharedAccountException('rejected');
    }
    WebSession session;
    try {
      session = await client.login(creds.identifier, creds.password);
    } on GreenWebException catch (e) {
      final fallback = creds.fallbackIdentifier;
      if (e.statusCode == 401 && fallback != null) {
        try {
          session = await client.login(fallback, creds.password);
        } on GreenWebException catch (e2) {
          throw _mapLoginError(e2);
        }
      } else {
        throw _mapLoginError(e);
      }
    }
    _rejectedAt = null;
    _token = session.token;
    try {
      await _secure.write(key: tokenKey, value: session.token);
    } catch (e) {
      debugPrint('Jeton GREEN Web non mémorisé (stockage chiffré) : $e');
    }
    return session.token;
  }

  Object _mapLoginError(GreenWebException e) {
    if (e.statusCode == 401) {
      _rejectedAt = _now();
      return const SharedAccountException('rejected');
    }
    if (e.statusCode == 403) return const SharedAccountException('disabled');
    return e;
  }

  Future<String?> _read() async {
    try {
      return await _secure.read(key: tokenKey);
    } catch (e) {
      debugPrint('Stockage chiffré illisible : $e');
      return null;
    }
  }

  bool _expiresSoon(String jwt) {
    final exp = jwtExpiry(jwt);
    return exp == null || exp.difference(_now()) < _renewBefore;
  }

  /// Date d'expiration (`exp`) d'un JWT, sans vérifier la signature (le
  /// serveur s'en charge). null si illisible.
  @visibleForTesting
  static DateTime? jwtExpiry(String jwt) {
    final parts = jwt.split('.');
    if (parts.length != 3) return null;
    try {
      final payload = jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(parts[1])))) as Map<String, dynamic>;
      final exp = (payload['exp'] as num?)?.toInt();
      return exp == null ? null : DateTime.fromMillisecondsSinceEpoch(exp * 1000, isUtc: true);
    } catch (_) {
      return null;
    }
  }
}
