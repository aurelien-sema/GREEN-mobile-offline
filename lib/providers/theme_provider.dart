import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider pour gérer le thème de l'application
class ThemeProvider with ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  ThemeMode _themeMode = ThemeMode.light;
  bool _isInitialized = false;

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  bool get isInitialized => _isInitialized;

  ThemeProvider() {
    _loadThemePreference();
  }

  /// Charger la préférence de thème depuis le stockage local
  Future<void> _loadThemePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedTheme = prefs.getString(_themeKey) ?? 'light';
      _themeMode = savedTheme == 'dark' ? ThemeMode.dark : ThemeMode.light;
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Erreur lors du chargement du thème: $e');
      _isInitialized = true;
      notifyListeners();
    }
  }

  /// Basculer entre le thème clair et sombre
  Future<void> toggleTheme() async {
    _themeMode = isDarkMode ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeKey, isDarkMode ? 'dark' : 'light');
    } catch (e) {
      debugPrint('Erreur lors de la sauvegarde du thème: $e');
    }
  }

  /// Définir le thème manuellement
  Future<void> setTheme(ThemeMode themeMode) async {
    if (_themeMode == themeMode) return;

    _themeMode = themeMode;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _themeKey,
        themeMode == ThemeMode.dark ? 'dark' : 'light',
      );
    } catch (e) {
      debugPrint('Erreur lors de la sauvegarde du thème: $e');
    }
  }
}
