import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:green_app/core/utils/text_input_formatters.dart';
import 'package:green_app/core/validation/validators.dart';

TextEditingValue _type(TextInputFormatter f, String text) =>
    f.formatEditUpdate(TextEditingValue.empty, TextEditingValue(text: text));

void main() {
  group('Validators', () {
    test('nom complet : deux mots, lettres accentuées acceptées', () {
      expect(Validators.name('Aurélien'), 'errNameFull');
      expect(Validators.name('TANKEU Aurélien'), isNull);
      expect(Validators.name("Marie-Claire N'Diaye"), isNull);
      expect(Validators.name('Jean 2'), 'errNameInvalid');
      expect(Validators.name(''), 'errNameRequired');
    });

    test('e-mail', () {
      expect(Validators.email('nom@exemple.cm'), isNull);
      expect(Validators.email('nom@exemple'), 'errEmailInvalid');
      expect(Validators.email(' '), 'errEmailRequired');
    });

    test('téléphone complet avec indicatif', () {
      expect(Validators.phone('+237699112233'), isNull);
      expect(Validators.phone('+237 699 11 22 33'), isNull);
      expect(Validators.phone('12345'), 'errPhoneInvalid');
    });

    test('mot de passe d\'un nouveau compte : 8 caractères, lettre et chiffre', () {
      expect(Validators.newPassword('abcdefgh'), 'errPasswordWeak');
      expect(Validators.newPassword('12345678'), 'errPasswordWeak');
      expect(Validators.newPassword('abc123'), 'errPasswordShort');
      expect(Validators.newPassword('champ2026'), isNull);
      expect(Validators.confirmPassword('a', 'b'), 'errPasswordMismatch');
    });

    test('réponse de sécurité', () {
      expect(Validators.securityAnswer('a'), 'errAnswerShort');
      expect(Validators.securityAnswer('Maïs'), isNull);
      expect(Validators.securityAnswer('x' * 61), 'errAnswerLong');
    });
  });

  group('Formateurs de saisie', () {
    test('le champ nom refuse chiffres et symboles', () {
      expect(_type(NameInputFormatter(), 'Awa2 Ngono!').text, 'Awa Ngono');
      expect(_type(NameInputFormatter(), 'Awa   Ngono').text, 'Awa Ngono');
    });

    test('le champ e-mail retire les espaces et passe en minuscules', () {
      expect(_type(EmailInputFormatter(), ' Nom@Exemple.CM ').text, 'nom@exemple.cm');
    });

    test('réponse sur une seule ligne', () {
      expect(_type(SingleLineTextFormatter(), 'mon\nvillage').text, 'mon village');
    });
  });
}
