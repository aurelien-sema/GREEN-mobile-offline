class Message {
  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final String? imageUrl;

  Message({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.imageUrl,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'content': content,
    'isUser': isUser,
    'timestamp': timestamp.toIso8601String(),
    'imageUrl': imageUrl,
  };

  factory Message.fromJson(Map<String, dynamic> json) => Message(
    id: json['id'] as String,
    content: json['content'] as String,
    isUser: json['isUser'] as bool,
    timestamp: DateTime.parse(json['timestamp'] as String),
    imageUrl: json['imageUrl'] as String?,
  );
}
