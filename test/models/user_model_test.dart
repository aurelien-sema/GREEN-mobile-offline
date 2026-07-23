import 'package:flutter_test/flutter_test.dart';
import 'package:green_app/models/user_model.dart';

void main() {
  group('UserModel', () {
    UserModel sample() => UserModel(
          id: 'u1',
          name: 'Jean Dupont',
          username: 'jdupont',
          email: 'jean@example.com',
          phone: '+237600000000',
          profession: 'Agriculteur',
          avatarUrl: 'assets/avatar.png',
          memberSince: DateTime(2025, 1, 15),
        );

    test('fromJson maps snake_case keys correctly', () {
      final json = {
        'id': 'u1',
        'name': 'Jean Dupont',
        'username': 'jdupont',
        'email': 'jean@example.com',
        'phone': '+237600000000',
        'profession': 'Agriculteur',
        'avatar_url': 'assets/avatar.png',
        'member_since': '2025-01-15T00:00:00.000',
      };
      final u = UserModel.fromJson(json);
      expect(u.id, 'u1');
      expect(u.avatarUrl, 'assets/avatar.png');
      expect(u.memberSince, DateTime.parse('2025-01-15T00:00:00.000'));
    });

    test('fromJson allows null optional fields', () {
      final json = {
        'id': 'u1',
        'name': 'Jean',
        'username': 'jean',
        'email': 'jean@example.com',
        'member_since': '2025-01-15T00:00:00.000',
      };
      final u = UserModel.fromJson(json);
      expect(u.phone, isNull);
      expect(u.profession, isNull);
      expect(u.avatarUrl, isNull);
    });

    test('toJson uses snake_case keys and round-trips', () {
      final u = sample();
      final json = u.toJson();
      expect(json['avatar_url'], 'assets/avatar.png');
      expect(json['member_since'], DateTime(2025, 1, 15).toIso8601String());
      final restored = UserModel.fromJson(json);
      expect(restored.toJson(), json);
    });

    test('copyWith overrides only provided fields', () {
      final u = sample();
      final updated = u.copyWith(name: 'Marie', email: 'marie@example.com');
      expect(updated.name, 'Marie');
      expect(updated.email, 'marie@example.com');
      expect(updated.id, u.id);
      expect(updated.username, u.username);
      expect(updated.phone, u.phone);
      expect(updated.memberSince, u.memberSince);
    });

    test('copyWith with no arguments preserves all fields', () {
      final u = sample();
      final copy = u.copyWith();
      expect(copy.toJson(), u.toJson());
    });
  });
}
