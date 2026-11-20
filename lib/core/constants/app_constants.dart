class AppConstants {
  // Font Sizes
  static const double fontSizeSmall = 12.0;
  static const double fontSizeRegular = 14.0;
  static const double fontSizeMedium = 16.0;
  static const double fontSizeLarge = 20.0;
  static const double fontSizeXLarge = 24.0;
  static const double fontSizeTitle = 28.0;

  // Padding & Spacing
  static const double paddingXSmall = 4.0;
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double paddingXLarge = 32.0;

  // Border Radius
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXLarge = 24.0;

  // Durées d'animation (Material 3 : retours courts, jamais décoratifs).
  // Désactivées automatiquement si l'utilisateur a coupé les animations
  // dans les réglages d'accessibilité d'Android (voir Motion.of).
  static const Duration animationFast = Duration(milliseconds: 150);
  static const Duration animationNormal = Duration(milliseconds: 250);
  static const Duration animationSlow = Duration(milliseconds: 400);

  // Validation
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 128;

  // Vision (détection de maladies) — classifier_v1, depuis la 2.2.0.
  // Seuil UNIQUE et global (pas de seuil par classe) appliqué à la
  // probabilité de la classe la plus probable parmi les 9 : en dessous, le
  // statut est « unknown » (voir lib/services/vision/decision_rule.dart).
  // PROVISOIRE : même valeur que le backend GREEN Web, à garder identique ;
  // sera réajusté quand des photos hors sujet auront été collectées.
  // Mesuré avec plant_classifier_float16.tflite : 91–92 % de réponses,
  // 96–97 % de réponses justes (contre 93–95 % sans seuil).
  // L'ancien critère d'écart avec la 2e classe (0,15) a été supprimé.
  static const double visionConfidenceThreshold = 0.70;

  // Comptes : au plus 4 comptes peuvent être créés depuis un même téléphone
  // (le 5e est refusé) ; la question de sécurité est demandée après 3 échecs.
  static const int maxAccountsPerDevice = 4;
  static const int maxFailedLoginsBeforeChallenge = 3;
  static const int maxFailedSecurityAnswers = 3;
  static const Duration securityLockDuration = Duration(minutes: 15);
}
