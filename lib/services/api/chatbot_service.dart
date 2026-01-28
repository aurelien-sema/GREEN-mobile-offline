import 'package:dio/dio.dart';
import '../../core/constants/app_constants.dart';
import '../../shared/models/message.dart';

class ChatbotService {
  late final Dio _dio;

  ChatbotService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.apiBaseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );

    _dio.interceptors.add(
      LogInterceptor(requestBody: true, responseBody: true),
    );
  }

  /// Envoyer un message au chatbot
  ///
  /// [message] : Contenu du message
  /// [context] : Contexte optionnel (ex: résultats de détection)
  /// [imageUrl] : URL de l'image en référence (optionnel)
  Future<Message> sendMessage({
    required String message,
    Map<String, dynamic>? context,
    String? imageUrl,
  }) async {
    try {
      final payload = {
        'message': message,
        if (context != null) 'context': context,
        if (imageUrl != null) 'image_url': imageUrl,
      };

      final response = await _dio.post(
        AppConstants.chatbotApiEndpoint,
        data: payload,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data as Map<String, dynamic>;
        return Message(
          id: data['id'] as String? ?? _generateId(),
          content: data['response'] as String,
          isUser: false,
          timestamp: DateTime.now(),
          imageUrl: data['image_url'] as String?,
        );
      } else {
        throw Exception('Erreur API Chatbot: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw Exception('Erreur lors de l\'envoi du message: $e');
    }
  }

  /// Obtenir l'historique des messages
  Future<List<Message>> getConversationHistory({
    int limit = 100,
    int offset = 0,
  }) async {
    try {
      final response = await _dio.get(
        '${AppConstants.chatbotApiEndpoint}/history',
        queryParameters: {'limit': limit, 'offset': offset},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data as List<dynamic>;
        return data
            .map((e) => Message.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Erreur lors de la récupération de l\'historique');
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw Exception('Erreur: $e');
    }
  }

  /// Effacer l'historique de conversation
  Future<void> clearHistory() async {
    try {
      final response = await _dio.delete(
        '${AppConstants.chatbotApiEndpoint}/history',
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Erreur lors de l\'effacement');
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw Exception('Erreur: $e');
    }
  }

  String _handleDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return 'Délai d\'attente dépassé - Vérifiez votre connexion';
      case DioExceptionType.receiveTimeout:
        return 'Le serveur met du temps à répondre, veuillez réessayer';
      case DioExceptionType.connectionError:
        return 'Erreur de connexion - Serveur indisponible';
      default:
        return 'Erreur réseau: ${e.message}';
    }
  }

  String _generateId() => DateTime.now().millisecondsSinceEpoch.toString();
}
