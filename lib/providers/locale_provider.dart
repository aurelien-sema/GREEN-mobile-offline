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
    _prefs = await SharedPreferences.getInstance();
    _locale = _prefs.getString(_localeKey) ?? 'fr';
    _initialized = true;
    notifyListeners();
  }

  /// Change the current locale and save to SharedPreferences.
  Future<void> setLocale(String newLocale) async {
    if (!AppStrings.availableLocales.contains(newLocale)) return;
    _locale = newLocale;
    await _prefs.setString(_localeKey, newLocale);
    notifyListeners();
  }

  /// Get localized string by key.
  String t(String key) => AppStrings.get(key, _locale);

  /// Get all available locales.
  List<String> get availableLocales => AppStrings.availableLocales;

  /// Get display name for a locale.
  String getLocaleName(String locale) =>
      AppStrings.localeNames[locale] ?? locale;
}
