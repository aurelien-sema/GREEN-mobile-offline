import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class ChatMessage {
  final String id;
  final String role; // 'user' or 'assistant'
  final String content;
  final DateTime timestamp;

  ChatMessage({
    String? id,
    required this.role,
    required this.content,
    DateTime? timestamp,
  })  : id = id ?? const Uuid().v4(),
        timestamp = timestamp ?? DateTime.now();

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        id: json['id'] ?? '',
        role: json['role'] ?? 'user',
        content: json['content'] ?? '',
        timestamp: json['timestamp'] != null
            ? DateTime.parse(json['timestamp'] as String)
            : DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'role': role,
        'content': content,
        'timestamp': timestamp.toIso8601String(),
      };
}

class ChatSession {
  final String id;
  final String title; // Summary/title of conversation
  final List<ChatMessage> messages;
  final DateTime createdAt;
  final DateTime updatedAt;

  ChatSession({
    String? id,
    String? title,
    List<ChatMessage>? messages,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        title = title ?? 'Nouvelle discussion',
        messages = messages ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory ChatSession.fromJson(Map<String, dynamic> json) => ChatSession(
        id: json['id'] ?? '',
        title: json['title'] ?? 'Nouvelle discussion',
        messages: (json['messages'] as List<dynamic>?)
                ?.map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : DateTime.now(),
        updatedAt: json['updated_at'] != null
            ? DateTime.parse(json['updated_at'] as String)
            : DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'messages': messages.map((m) => m.toJson()).toList(),
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };
}

class ChatHistoryService {
  static const String _fileName = 'chat_history.json';
  List<ChatSession> _sessions = [];
  ChatSession? _currentSession;

  Future<File> _getFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_fileName');
  }

  Future<void> _load() async {
    if (_sessions.isNotEmpty) return;
    try {
      final file = await _getFile();
      if (!await file.exists()) {
        _sessions = [];
        return;
      }
      final content = await file.readAsString();
      final list = jsonDecode(content) as List<dynamic>;
      _sessions = list
          .map((e) => ChatSession.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      _sessions = [];
    }
  }

  Future<void> _save() async {
    final file = await _getFile();
    await file.writeAsString(
      jsonEncode(_sessions.map((e) => e.toJson()).toList()),
    );
  }

  /// Create a new chat session
  Future<ChatSession> createNewSession() async {
    await _load();
    final session = ChatSession();
    _currentSession = session;
    _sessions.insert(0, session); // Most recent first
    await _save();
    return session;
  }

  /// Get all sessions (sorted by most recent first)
  Future<List<ChatSession>> getAllSessions() async {
    await _load();
    return _sessions;
  }

  /// Get a specific session by ID
  Future<ChatSession?> getSessionById(String id) async {
    await _load();
    try {
      return _sessions.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Add a message to the current session
  Future<void> addMessageToCurrentSession(ChatMessage message) async {
    if (_currentSession == null) {
      await createNewSession();
    }
    _currentSession!.messages.add(message);
    _currentSession = _currentSession!;
    await _updateSessionInList();
  }

  /// Update title of current session (e.g., after first response)
  Future<void> updateCurrentSessionTitle(String newTitle) async {
    if (_currentSession == null) return;
    _currentSession = ChatSession(
      id: _currentSession!.id,
      title: newTitle,
      messages: _currentSession!.messages,
      createdAt: _currentSession!.createdAt,
      updatedAt: DateTime.now(),
    );
    await _updateSessionInList();
  }

  /// Switch to a different session
  Future<void> switchToSession(String sessionId) async {
    final session = await getSessionById(sessionId);
    if (session != null) {
      _currentSession = session;
    }
  }

  /// Delete a session by ID
  Future<void> deleteSession(String sessionId) async {
    await _load();
    _sessions.removeWhere((s) => s.id == sessionId);
    if (_currentSession?.id == sessionId) {
      _currentSession = null;
    }
    await _save();
  }

  /// Get current session
  ChatSession? getCurrentSession() => _currentSession;

  /// Clear current session (for new chat)
  Future<void> clearCurrentSession() async {
    _currentSession = null;
  }

  /// Private: update session in list and save
  Future<void> _updateSessionInList() async {
    if (_currentSession == null) return;
    final idx = _sessions.indexWhere((s) => s.id == _currentSession!.id);
    if (idx >= 0) {
      _sessions.removeAt(idx);
    }
    _sessions.insert(
      0,
      ChatSession(
        id: _currentSession!.id,
        title: _currentSession!.title,
        messages: _currentSession!.messages,
        createdAt: _currentSession!.createdAt,
        updatedAt: DateTime.now(),
      ),
    );
    await _save();
  }
}

final chatHistoryService = ChatHistoryService();
