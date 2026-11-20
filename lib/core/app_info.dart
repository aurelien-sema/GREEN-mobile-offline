/// Identité et version de l'application, affichées dans « À propos » et
/// « Paramètres ».
///
/// [version] et [buildNumber] doivent rester identiques à la ligne
/// `version:` de pubspec.yaml : test/app_info_test.dart échoue sinon.
class AppInfo {
  AppInfo._();

  static const String name = 'GREEN';
  // 2.2.0 (4) : classifier_v1, règle ok / unknown / wrong_crop.
  static const String version = '2.2.0';
  static const int buildNumber = 4;
  static const String releaseDate = '2026-11-20';

  /// Texte complet, ex. « 2.1.0 (3) ».
  static String get fullVersion => '$version ($buildNumber)';
}
