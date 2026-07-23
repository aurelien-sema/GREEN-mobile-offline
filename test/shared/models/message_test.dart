import 'package:flutter_test/flutter_test.dart';
import 'package:green_app/shared/models/message.dart';

void main() {
  group('Message', () {
    test('toJson serializes fields and ISO timestamp', () {
      final m = Message(
        id: 'm1',
        content: 'Bonjour',
        isUser: true,
        timestamp: DateTime(2026, 2, 3, 14, 30),
        imageUrl: 'assets/img.png',
      );
      final json = m.toJson();
      expect(json['id'], 'm1');
      expect(json['content'], 'Bonjour');
      expect(json['isUser'], true);
      expect(json['timestamp'], DateTime(2026, 2, 3, 14, 30).toIso8601String());
      expect(json['imageUrl'], 'assets/img.png');
    });

    test('fromJson parses fields including null imageUrl', () {
      final m = Message.fromJson({
        'id': 'm2',
        'content': 'Réponse',
        'isUser': false,
        'timestamp': '2026-02-03T14:30:00.000',
        'imageUrl': null,
      });
      expect(m.id, 'm2');
      expect(m.isUser, false);
      expect(m.timestamp, DateTime.parse('2026-02-03T14:30:00.000'));
      expect(m.imageUrl, isNull);
    });

    test('round-trips through toJson/fromJson', () {
      final original = Message(
        id: 'm3',
        content: 'Test',
        isUser: true,
        timestamp: DateTime(2026, 1, 1, 9, 0),
      );
      final restored = Message.fromJson(original.toJson());
      expect(restored.toJson(), original.toJson());
    });
  });
}
