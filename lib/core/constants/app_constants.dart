class AppConstants {
  // API Configuration
  static const String apiBaseUrl = 'http://localhost:8000';
  static const String visionApiEndpoint = '/api/vision/detect';
  static const String chatbotApiEndpoint = '/api/chat/message';

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

  // Animation Durations
  static const Duration animationFast = Duration(milliseconds: 360);
  static const Duration animationNormal = Duration(milliseconds: 600);
  static const Duration animationSlow = Duration(milliseconds: 1000);

  // Storage Keys
  static const String themeKey = 'theme_mode';
  static const String userToken = 'user_token';
  static const String userId = 'user_id';
  static const String userName = 'user_name';
  static const String userEmail = 'user_email';

  // Validation
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 128;
}
