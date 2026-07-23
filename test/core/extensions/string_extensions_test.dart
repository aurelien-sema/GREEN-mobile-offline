import 'package:flutter_test/flutter_test.dart';
import 'package:green_app/core/extensions/string_extensions.dart';

void main() {
  group('StringExtensions.isValidEmail', () {
    test('returns true for well-formed emails', () {
      expect('user@example.com'.isValidEmail, isTrue);
    });

    test('returns false for malformed emails', () {
      expect('userexample.com'.isValidEmail, isFalse);
      expect('user @example.com'.isValidEmail, isFalse);
      expect(''.isValidEmail, isFalse);
    });
  });

  group('StringExtensions.isValidPassword', () {
    test('is true only for 8+ character strings', () {
      expect('12345678'.isValidPassword, isTrue);
      expect('1234567'.isValidPassword, isFalse);
    });
  });

  group('StringExtensions.isNotBlank', () {
    test('is false for empty or whitespace-only strings', () {
      expect(''.isNotBlank, isFalse);
      expect('   '.isNotBlank, isFalse);
    });

    test('is true when there is non-whitespace content', () {
      expect('  hi  '.isNotBlank, isTrue);
    });
  });

  group('StringExtensions.capitalize', () {
    test('capitalizes first letter and lowercases the rest', () {
      expect('hELLO'.capitalize, 'Hello');
      expect('a'.capitalize, 'A');
    });

    test('returns the original string when empty', () {
      expect(''.capitalize, '');
    });
  });

  group('StringExtensions.capitalizeAll', () {
    test('capitalizes each space-separated word', () {
      expect('hello wORLD'.capitalizeAll, 'Hello World');
    });
  });

  group('StringExtensions.truncate', () {
    test('leaves strings of 50 chars or fewer unchanged', () {
      final s = 'a' * 50;
      expect(s.truncate, s);
    });

    test('truncates longer strings to 47 chars plus ellipsis', () {
      final s = 'a' * 60;
      final result = s.truncate;
      expect(result.length, 50);
      expect(result.endsWith('...'), isTrue);
      expect(result, '${'a' * 47}...');
    });
  });
}
