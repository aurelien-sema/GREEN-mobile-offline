import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/user_scope.dart';

/// Session de l'utilisateur connecté.
///
/// Seul l'identifiant du compte est gardé dans les préférences ; le profil
/// (dont la photo) est relu dans users.json à chaque démarrage. Avant la v2,
/// tout le profil vivait dans un cache effacé à la déconnexion : la photo de
/// profil disparaissait donc à chaque reconnexion.
class AuthProvider with ChangeNotifier {
  static const _sessionKey = 'session_account_id';
  static const _legacyCacheKey = 'auth_user_cache';

  final AuthService _auth;
  UserModel? _currentUser;

  AuthProvider({AuthService? service}) : _auth = service ?? authService;

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;

  Future<void> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    var id = prefs.getString(_sessionKey);

    // Migration de la session v1 (profil complet en cache).
    final legacy = prefs.getString(_legacyCacheKey);
    if (id == null && legacy != null) {
      try {
        final json = jsonDecode(legacy) as Map<String, dynamic>;
        id = json['id'] as String?;
        final oldAvatar = json['avatar_url'] as String?;
        if (id != null && oldAvatar != null && File(oldAvatar).existsSync()) {
          final account = await _auth.findById(id);
          if (account != null && account.avatarPath == null) {
            await _auth.setAvatarPath(id, oldAvatar);
          }
        }
        if (id != null) await prefs.setString(_sessionKey, id);
      } catch (e) {
        debugPrint('Migration de session ignorée : $e');
      }
      await prefs.remove(_legacyCacheKey);
    }

    if (id == null) return;
    final account = await _auth.findById(id);
    if (account == null) {
      await prefs.remove(_sessionKey);
      return;
    }
    _setUser(UserModel.fromAccount(account));
  }

  Future<void> signIn(AccountRecord account) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionKey, account.id);
    _setUser(UserModel.fromAccount(account));
  }

  /// Relit le profil depuis users.json (après une modification).
  Future<void> refresh() async {
    final id = _currentUser?.id;
    if (id == null) return;
    final account = await _auth.findById(id);
    if (account != null) _setUser(UserModel.fromAccount(account));
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
    _currentUser = null;
    UserScope.setUserId(null);
    notifyListeners();
  }

  void _setUser(UserModel user) {
    _currentUser = user;
    UserScope.setUserId(user.id);
    notifyListeners();
  }
}
