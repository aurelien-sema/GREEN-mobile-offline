/// Modèle pour les messages du chat
class ChatMessageModel {
  final String id;
  final String message;
  final bool isUser;
  final DateTime timestamp;
  final String? imageUrl;
  final MessageStatus status;

  ChatMessageModel({
    required this.id,
    required this.message,
    required this.isUser,
    required this.timestamp,
    this.imageUrl,
    this.status = MessageStatus.sent,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id'] as String,
      message: json['message'] as String,
      isUser: json['is_user'] as bool,
      timestamp: DateTime.parse(json['timestamp'] as String),
      imageUrl: json['image_url'] as String?,
      status: MessageStatus.fromString(json['status'] as String? ?? 'sent'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'message': message,
      'is_user': isUser,
      'timestamp': timestamp.toIso8601String(),
      'image_url': imageUrl,
      'status': status.toString(),
    };
  }

  ChatMessageModel copyWith({
    String? id,
    String? message,
    bool? isUser,
    DateTime? timestamp,
    String? imageUrl,
    MessageStatus? status,
  }) {
    return ChatMessageModel(
      id: id ?? this.id,
      message: message ?? this.message,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      imageUrl: imageUrl ?? this.imageUrl,
      status: status ?? this.status,
    );
  }
}

/// Statut des messages
enum MessageStatus {
  sending,
  sent,
  error;

  static MessageStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'sending':
        return MessageStatus.sending;
      case 'sent':
        return MessageStatus.sent;
      case 'error':
        return MessageStatus.error;
      default:
        return MessageStatus.sent;
    }
  }

  @override
  String toString() {
    return name;
  }
}
