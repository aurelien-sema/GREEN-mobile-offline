import 'dart:io';
import 'dart:convert';
import 'package:green_app/config/api_config.dart';
import 'package:green_app/models/chat_message_model.dart';
import 'package:http/http.dart' as http;

/// Service pour l'intégration du chatbot Python
class ChatbotService {
  final List<Map<String, String>> _conversationHistory = [];

  /// Envoyer un message au chatbot
  Future<String> sendMessage(String message) async {
    try {
      // Ajouter le message à l'historique
      _conversationHistory.add({'role': 'user', 'content': message});

      final url = Uri.parse(ApiConfig.getChatbotUrl(ApiConfig.chatSendMessage));

      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'message': message,
              'history': _conversationHistory,
              'timestamp': DateTime.now().toIso8601String(),
            }),
          )
          .timeout(ApiConfig.connectionTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final botResponse =
            data['response'] as String? ?? 'Désolé, je n\'ai pas compris.';

        // Ajouter la réponse à l'historique
        _conversationHistory.add({'role': 'assistant', 'content': botResponse});

        return botResponse;
      } else {
        throw Exception('Erreur API: ${response.statusCode}');
      }
    } catch (e) {
      // Mode démo en cas d'erreur
      return 'Désolé, je n\'ai pas pu traiter votre demande.';
    }
  }

  /// Envoyer un message avec une image
  Future<String> sendMessageWithImage(String message, File imageFile) async {
    try {
      // Lire l'image et la convertir en base64
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      final url = Uri.parse(ApiConfig.getChatbotUrl(ApiConfig.chatSendMessage));

      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'message': message,
              'image': base64Image,
              'history': _conversationHistory,
              'timestamp': DateTime.now().toIso8601String(),
            }),
          )
          .timeout(ApiConfig.connectionTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final botResponse =
            data['response'] as String? ?? 'Désolé, je n\'ai pas compris.';

        return botResponse;
      } else {
        throw Exception('Erreur API: ${response.statusCode}');
      }
    } catch (e) {
      // Mode démo en cas d'erreur
      return 'Cela pourrait être une carence en magnésium. Pouvez-vous m\'envoyer une photo ?';
    }
  }

  /// Obtenir l'historique du chat
  Future<List<ChatMessageModel>> getChatHistory() async {
    try {
      final url = Uri.parse(ApiConfig.getChatbotUrl(ApiConfig.chatHistory));

      final response = await http.get(url).timeout(ApiConfig.connectionTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List<dynamic>;
        return data
            .map(
              (item) => ChatMessageModel.fromJson(item as Map<String, dynamic>),
            )
            .toList();
      } else {
        throw Exception('Erreur de chargement de l\'historique');
      }
    } catch (e) {
      return [];
    }
  }

  /// Effacer l'historique du chat
  Future<void> clearHistory() async {
    try {
      final url = Uri.parse(
        ApiConfig.getChatbotUrl(ApiConfig.chatClearHistory),
      );

      await http.post(url).timeout(ApiConfig.connectionTimeout);
      _conversationHistory.clear();
    } catch (e) {
      _conversationHistory.clear();
    }
  }
}
