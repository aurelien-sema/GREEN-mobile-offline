import 'dart:io';
import 'package:flutter/material.dart';
import 'package:green_app/models/chat_message_model.dart';
import 'package:green_app/services/chatbot_service.dart';
import 'package:uuid/uuid.dart';

/// Provider pour gérer le chat avec le bot
class ChatProvider with ChangeNotifier {
  final ChatbotService _chatbotService = ChatbotService();
  final Uuid _uuid = const Uuid();

  List<ChatMessageModel> _messages = [];
  bool _isTyping = false;
  String? _error;

  List<ChatMessageModel> get messages => _messages;
  bool get isTyping => _isTyping;
  String? get error => _error;

  ChatProvider() {
    _initializeChat();
  }

  /// Initialiser le chat avec un message de bienvenue
  void _initializeChat() {
    _messages.add(
      ChatMessageModel(
        id: _uuid.v4(),
        message: 'Bonjour ! Comment puis-je vous aider aujourd\'hui ?',
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );
  }

  /// Envoyer un message texte
  Future<void> sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    // Ajouter le message de l'utilisateur
    final userMessage = ChatMessageModel(
      id: _uuid.v4(),
      message: message,
      isUser: true,
      timestamp: DateTime.now(),
    );

    _messages.add(userMessage);
    _isTyping = true;
    _error = null;
    notifyListeners();

    try {
      // Envoyer au chatbot et obtenir la réponse
      final response = await _chatbotService.sendMessage(message);

      // Ajouter la réponse du bot
      final botMessage = ChatMessageModel(
        id: _uuid.v4(),
        message: response,
        isUser: false,
        timestamp: DateTime.now(),
      );

      _messages.add(botMessage);
      _isTyping = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isTyping = false;
      notifyListeners();
      debugPrint('Erreur d\'envoi du message: $e');
    }
  }

  /// Envoyer un message avec une image
  Future<void> sendMessageWithImage(String message, File imageFile) async {
    // Ajouter le message de l'utilisateur
    final userMessage = ChatMessageModel(
      id: _uuid.v4(),
      message: message,
      isUser: true,
      timestamp: DateTime.now(),
      imageUrl: imageFile.path,
    );

    _messages.add(userMessage);
    _isTyping = true;
    _error = null;
    notifyListeners();

    try {
      // Envoyer au chatbot avec l'image
      final response = await _chatbotService.sendMessageWithImage(
        message,
        imageFile,
      );

      // Ajouter la réponse du bot
      final botMessage = ChatMessageModel(
        id: _uuid.v4(),
        message: response,
        isUser: false,
        timestamp: DateTime.now(),
      );

      _messages.add(botMessage);
      _isTyping = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isTyping = false;
      notifyListeners();
      debugPrint('Erreur d\'envoi du message avec image: $e');
    }
  }

  /// Effacer l'historique du chat
  Future<void> clearHistory() async {
    try {
      await _chatbotService.clearHistory();
      _messages.clear();
      _initializeChat();
      notifyListeners();
    } catch (e) {
      debugPrint('Erreur d\'effacement de l\'historique: $e');
    }
  }

  /// Charger l'historique du chat
  Future<void> loadHistory() async {
    try {
      _messages = await _chatbotService.getChatHistory();
      notifyListeners();
    } catch (e) {
      debugPrint('Erreur de chargement de l\'historique: $e');
    }
  }
}
