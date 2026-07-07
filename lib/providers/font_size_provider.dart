import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_strings.dart';

/// Font size enum with normalized scale values.
enum FontSize {
  small(0.85),
  medium(1.0),
  large(1.15),
  extraLarge(1.3);

  final double scale;
  const FontSize(this.scale);

  /// Get display name for the font size, réutilisant la table de
  /// traductions unique d'AppStrings plutôt que d'en dupliquer une copie
  /// (qui divergeait déjà : il manquait la 4e taille ici).
  String getDisplayName(String locale) => AppStrings.get(name, locale);
}

/// Provider for managing app font size.
/// Persists selected font size to SharedPreferences and notifies listeners of changes.
/// Use the [scale] property to multiply text theme font sizes.
class FontSizeProvider extends ChangeNotifier {
  static const String _fontSizeKey = 'app_font_size';
  FontSize _fontSize = FontSize.medium;
  late SharedPreferences _prefs;
  bool _initialized = false;

  FontSize get fontSize => _fontSize;
  double get scale => _fontSize.scale;

  /// Initialize the provider by loading saved font size from SharedPreferences.
  Future<void> initialize() async {
    if (_initialized) return;
    try {
      _prefs = await SharedPreferences.getInstance();
      final savedSize = _prefs.getString(_fontSizeKey);
      if (savedSize != null) {
        _fontSize = FontSize.values.firstWhere(
          (fs) => fs.name == savedSize,
          orElse: () => FontSize.medium,
        );
      }
      _initialized = true;
      debugPrint('FontSizeProvider initialized successfully: ${_fontSize.name}');
    } catch (e) {
      debugPrint('Error initializing FontSizeProvider: $e. Using default size.');
      _fontSize = FontSize.medium; // Fallback to default
      _initialized = true;
    }
    notifyListeners();
  }

  /// Change the current font size and save to SharedPreferences.
  Future<void> setFontSize(FontSize newSize) async {
    _fontSize = newSize;
    await _prefs.setString(_fontSizeKey, newSize.name);
    notifyListeners();
  }

  /// Get all available font sizes.
  List<FontSize> get availableSizes => FontSize.values;

  /// Get display name for a font size in the given locale.
  String getSizeName(FontSize size, String locale) => size.getDisplayName(locale);
}
