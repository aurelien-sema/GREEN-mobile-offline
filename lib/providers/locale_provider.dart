import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_strings.dart';

/// Provider for managing app localization.
/// Persists selected locale to SharedPreferences and notifies listeners of changes.
class LocaleProvider extends ChangeNotifier {
  static const String _localeKey = 'app_locale';
  String _locale = 'fr'; // Default to French
  late SharedPreferences _prefs;
  bool _initialized = false;

  String get locale => _locale;

  /// Initialize the provider by loading saved locale from SharedPreferences.
  Future<void> initialize() async {
    if (_initialized) return;
    try {
      _prefs = await SharedPreferences.getInstance();
      _locale = _prefs.getString(_localeKey) ?? 'fr';
      _initialized = true;
      debugPrint('LocaleProvider initialized successfully: $_locale');
    } catch (e) {
      debugPrint('Error initializing LocaleProvider: $e. Using default locale.');
      _locale = 'fr'; // Fallback to default
      _initialized = true;
    }
    notifyListeners();
  }

  /// Change the current locale and save to SharedPreferences.
  Future<void> setLocale(String newLocale) async {
    if (!AppStrings.availableLocales.contains(newLocale)) return;
    _locale = newLocale;
    notifyListeners();
    try {
      _prefs = await SharedPreferences.getInstance();
      await _prefs.setString(_localeKey, newLocale);
    } catch (e) {
      debugPrint('Langue non enregistrée : $e');
    }
  }

  /// Get localized string by key.
  String t(String key) => AppStrings.get(key, _locale);

  /// Texte traduit avec paramètres : tf('attemptsLeft', {'n': 2}) remplace {n}.
  String tf(String key, Map<String, Object> params) {
    var s = AppStrings.get(key, _locale);
    params.forEach((k, v) => s = s.replaceAll('{$k}', '$v'));
    return s;
  }

  /// Locale Intl / Flutter correspondante (le pidgin utilise l'anglais).
  String get materialLanguage => _locale == 'fr' ? 'fr' : 'en';

  /// Get all available locales.
  List<String> get availableLocales => AppStrings.availableLocales;

  /// Get display name for a locale.
  String getLocaleName(String locale) =>
      AppStrings.localeNames[locale] ?? locale;
}
