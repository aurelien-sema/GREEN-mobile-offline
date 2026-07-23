import 'package:flutter_test/flutter_test.dart';
import 'package:green_app/core/utils/disease_status.dart';

void main() {
  group('isHealthyDiseaseName', () {
    test('is true when the name contains "sain" (case-insensitive)', () {
      expect(isHealthyDiseaseName('Plante saine'), isTrue);
      expect(isHealthyDiseaseName('SAIN'), isTrue);
      expect(isHealthyDiseaseName('Tomate - sain'), isTrue);
    });

    test('is false for disease names not containing "sain"', () {
      expect(isHealthyDiseaseName('Mildiou'), isFalse);
      expect(isHealthyDiseaseName(''), isFalse);
      expect(isHealthyDiseaseName('healthy'), isFalse);
    });
  });
}
