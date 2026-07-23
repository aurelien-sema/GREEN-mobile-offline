import 'package:flutter_test/flutter_test.dart';
import 'package:green_app/core/validation/validators.dart';

void main() {
  group('Validators.validateName', () {
    test('rejects null and empty/whitespace input', () {
      expect(Validators.validateName(null), 'Nom requis');
      expect(Validators.validateName(''), 'Nom requis');
      expect(Validators.validateName('   '), 'Nom requis');
    });

    test('accepts names with accents, spaces, hyphens and dots', () {
      expect(Validators.validateName('Jean-Pierre'), isNull);
      expect(Validators.validateName('Éloïse'), isNull);
      expect(Validators.validateName('J. Dupont'), isNull);
    });

    test('rejects names with digits or invalid characters', () {
      expect(Validators.validateName('Jean123'), 'Nom invalide');
      expect(Validators.validateName('name@domain'), 'Nom invalide');
    });

    test('rejects names longer than 64 characters', () {
      expect(Validators.validateName('a' * 65), 'Nom invalide');
    });
  });

  group('Validators.validateEmail', () {
    test('rejects null and empty input', () {
      expect(Validators.validateEmail(null), 'Email requis');
      expect(Validators.validateEmail(''), 'Email requis');
    });

    test('accepts valid email addresses', () {
      expect(Validators.validateEmail('user@example.com'), isNull);
      expect(Validators.validateEmail('first.last@sub.domain.org'), isNull);
    });

    test('rejects malformed email addresses', () {
      expect(Validators.validateEmail('plainaddress'), 'Email invalide');
      expect(Validators.validateEmail('missing@tld'), 'Email invalide');
      expect(Validators.validateEmail('@example.com'), 'Email invalide');
    });
  });

  group('Validators.validatePhone', () {
    test('rejects null and empty input', () {
      expect(Validators.validatePhone(null), 'Téléphone requis');
      expect(Validators.validatePhone(''), 'Téléphone requis');
    });

    test('accepts phone numbers with +, spaces, dashes and parentheses', () {
      expect(Validators.validatePhone('+237 6 00 00 00 00'), isNull);
      expect(Validators.validatePhone('(237)-600-000'), isNull);
    });

    test('rejects too-short numbers and letters', () {
      expect(Validators.validatePhone('12345'), 'Numéro de téléphone invalide');
      expect(Validators.validatePhone('phone123'), 'Numéro de téléphone invalide');
    });
  });

  group('Validators.validatePassword', () {
    test('rejects null and empty input', () {
      expect(Validators.validatePassword(null), 'Mot de passe requis');
      expect(Validators.validatePassword(''), 'Mot de passe requis');
    });

    test('rejects passwords shorter than 8 characters', () {
      expect(
        Validators.validatePassword('short'),
        'Mot de passe trop court (8+ caractères)',
      );
    });

    test('accepts passwords with at least 8 characters', () {
      expect(Validators.validatePassword('12345678'), isNull);
      expect(Validators.validatePassword('mötdepàsse!'), isNull);
    });
  });
}
