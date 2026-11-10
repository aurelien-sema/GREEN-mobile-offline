/// Identité et version de l'application, affichées dans « À propos » et
/// « Paramètres ».
///
/// [version] et [buildNumber] doivent rester identiques à la ligne
/// `version:` de pubspec.yaml : test/app_info_test.dart échoue sinon.
class AppInfo {
  AppInfo._();

  static const String name = 'GREEN';
  static const String version = '2.1.0';
  static const int buildNumber = 3;
  static const String releaseDate = '2026-11-09';

  /// Texte complet, ex. « 2.1.0 (3) ».
  static String get fullVersion => '$version ($buildNumber)';
}
