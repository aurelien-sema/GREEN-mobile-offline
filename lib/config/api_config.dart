/// Configuration des endpoints API pour les modèles Python
class ApiConfig {
  // Base URLs - À configurer selon votre déploiement
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000',
  );

  static const String visionBaseUrl = String.fromEnvironment(
    'VISION_API_URL',
    defaultValue: 'http://localhost:8001',
  );

  static const String chatbotBaseUrl = String.fromEnvironment(
    'CHATBOT_API_URL',
    defaultValue: 'http://localhost:8002',
  );

  // Endpoints - Vision API (Modèle de vision par ordinateur)
  static const String visionAnalyze = '/api/vision/analyze';
  static const String visionHistory = '/api/vision/history';

  // Endpoints - Chatbot API
  static const String chatSendMessage = '/api/chat/message';
  static const String chatHistory = '/api/chat/history';
  static const String chatClearHistory = '/api/chat/clear';

  // Endpoints - Auth
  static const String authLogin = '/api/auth/login';
  static const String authRegister = '/api/auth/register';
  static const String authLogout = '/api/auth/logout';

  // Endpoints - User
  static const String userProfile = '/api/user/profile';
  static const String userUpdate = '/api/user/update';

  // Timeouts
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // Retry configuration
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 2);

  /// Obtenir l'URL complète pour un endpoint de vision
  static String getVisionUrl(String endpoint) {
    return '$visionBaseUrl$endpoint';
  }

  /// Obtenir l'URL complète pour un endpoint de chatbot
  static String getChatbotUrl(String endpoint) {
    return '$chatbotBaseUrl$endpoint';
  }

  /// Obtenir l'URL complète pour un endpoint général
  static String getUrl(String endpoint) {
    return '$baseUrl$endpoint';
  }
}
