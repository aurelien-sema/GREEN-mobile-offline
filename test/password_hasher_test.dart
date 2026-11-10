import 'package:flutter_test/flutter_test.dart';
import 'package:green_app/services/auth/password_hasher.dart';

void main() {
  group('PasswordHasher', () {
    test('un hachage se vérifie avec le bon secret seulement', () async {
      final h = await PasswordHasher.hash('Mais2026');
      expect(h, startsWith('pbkdf2_sha256\$${PasswordHasher.iterations}\$'));
      expect(await PasswordHasher.verify('Mais2026', h), isTrue);
      expect(await PasswordHasher.verify('mais2026', h), isFalse);
    });

    test('deux hachages du même secret diffèrent (sel aléatoire)', () {
      expect(PasswordHasher.hashSync('abc', rounds: 10), isNot(PasswordHasher.hashSync('abc', rounds: 10)));
    });

    test('les hachages v1 (10 000 itérations) restent valides', () {
      final legacy = PasswordHasher.hashSync('ancienMotDePasse1', rounds: 10000);
      expect(PasswordHasher.verifySync('ancienMotDePasse1', legacy), isTrue);
    });

    test('une valeur stockée mal formée est refusée sans exception', () {
      expect(PasswordHasher.verifySync('x', 'pas-un-hachage'), isFalse);
      expect(PasswordHasher.verifySync('x', r'pbkdf2_sha256$abc$$'), isFalse);
    });
  });

  group('normalizeSecret', () {
    test('ignore casse, accents, ponctuation et espaces multiples', () {
      expect(normalizeSecret('  Maïs '), 'mais');
      expect(normalizeSecret('TANKEU  Sema-Aurélien'), 'tankeu sema aurelien');
      expect(normalizeSecret("N'Djamena"), 'n djamena');
    });
  });
}
