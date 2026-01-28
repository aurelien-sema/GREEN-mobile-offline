import 'package:flutter/material.dart';

/// Provider pour gérer les paramètres globaux (langue, thème, etc.)
class AppSettingsProvider with ChangeNotifier {
  String _language = 'fr';
  String _botName = 'Green Bot';

  String get language => _language;
  String get botName => _botName;

  void setLanguage(String lang) {
    if (_language != lang) {
      _language = lang;
      notifyListeners();
    }
  }

  void setBotName(String name) {
    _botName = name;
    notifyListeners();
  }
}
