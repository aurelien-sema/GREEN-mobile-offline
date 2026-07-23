import 'package:flutter_test/flutter_test.dart';
import 'package:green_app/core/utils/text_input_formatters.dart';

TextEditingValue _val(String text) => TextEditingValue(text: text);

void main() {
  group('CapitalizeSentencesFormatter', () {
    final formatter = CapitalizeSentencesFormatter();

    TextEditingValue format(String text) =>
        formatter.formatEditUpdate(TextEditingValue.empty, _val(text));

    test('leaves empty text untouched', () {
      expect(format('').text, '');
    });

    test('capitalizes the first character', () {
      expect(format('hello').text, 'Hello');
    });

    test('capitalizes the character after ". "', () {
      expect(format('hello world. good day').text, 'Hello world. Good day');
    });

    test('does not capitalize after a period without a following space', () {
      expect(format('a.b.c').text, 'A.b.c');
    });

    test('leaves already-capitalized text unchanged', () {
      expect(format('Hello. World').text, 'Hello. World');
    });
  });

  group('NameInputFormatter', () {
    final formatter = NameInputFormatter();

    TextEditingValue format(String text) =>
        formatter.formatEditUpdate(TextEditingValue.empty, _val(text));

    test('delegates to sentence capitalization behaviour', () {
      expect(format('jean. pierre').text, 'Jean. Pierre');
    });

    test('leaves empty text untouched', () {
      expect(format('').text, '');
    });
  });
}
