import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:green_app/models/user_model.dart';
import 'package:green_app/services/auth_service.dart' as svc;
import 'package:green_app/services/auth_service.dart' show authService;

/// Provider pour gérer l'authentification
class AuthProvider with ChangeNotifier {
  UserModel? _currentUser;
  bool _isAuthenticated = false;
  bool _isLoading = false;
  static const String _cacheKey = 'auth_user_cache';

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;

  /// Connexion utilisateur
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final svc.UserModel? svcUser = await authService
          .loginWithIdentifierAndPassword(email, password);
      if (svcUser == null) {
        _isLoading = false;
        notifyListeners();
        return false;
      }
      _currentUser = UserModel(
        id: svcUser.id,
        name: svcUser.name,
        username: svcUser.email.split('@').first,
        email: svcUser.email,
        phone: svcUser.phone,
        profession: null,
        memberSince: DateTime.now(),
      );
      _isAuthenticated = true;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      debugPrint('Erreur de connexion: $e');
      return false;
    }
  }

  /// Inscription utilisateur
  Future<bool> register(String name, String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      // The actual registration flow may be handled from the screens via authService
      _currentUser = UserModel(
        id: id,
        name: name,
        username: email.split('@').first,
        email: email,
        memberSince: DateTime.now(),
      );
      _isAuthenticated = true;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      debugPrint('Erreur d\'inscription: $e');
      return false;
    }
  }

  /// Déconnexion
  Future<void> logout() async {
    _currentUser = null;
    _isAuthenticated = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheKey);
    notifyListeners();
  }

  /// Mettre à jour le profil utilisateur
  Future<bool> updateProfile(UserModel updatedUser) async {
    try {
      // TODO: Implémenter l'appel API réel
      await Future.delayed(const Duration(seconds: 1));

      _currentUser = updatedUser;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Erreur de mise à jour du profil: $e');
      return false;
    }
  }

  /// Helper to set current user from the internal auth service model
  void setCurrentUserFromService(svc.UserModel svcUser) {
    _currentUser = UserModel(
      id: svcUser.id,
      name: svcUser.name,
      username: svcUser.email.contains('@')
          ? svcUser.email.split('@').first
          : (svcUser.phone.isNotEmpty ? svcUser.phone : svcUser.id),
      email: svcUser.email,
      phone: svcUser.phone.isNotEmpty ? svcUser.phone : null,
      profession: null,
      memberSince: DateTime.now(),
    );
    _isAuthenticated = true;
    _saveToCache();
    notifyListeners();
  }

  /// Sauvegarder l'utilisateur actuel en cache (SharedPreferences)
  Future<void> _saveToCache() async {
    if (_currentUser == null) return;
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(_currentUser?.toJson() ?? {});
    await prefs.setString(_cacheKey, json);
  }

  /// Restaurer l'utilisateur depuis le cache au démarrage
  Future<void> restoreFromCache() async {
    _isLoading = true;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_cacheKey);
    if (cached != null) {
      try {
        final decoded = jsonDecode(cached) as Map<String, dynamic>;
        _currentUser = UserModel.fromJson(decoded);
        _isAuthenticated = true;
      } catch (e) {
        debugPrint('Erreur restauration cache: $e');
        _currentUser = null;
        _isAuthenticated = false;
      }
    }
    _isLoading = false;
    notifyListeners();
  }
}
