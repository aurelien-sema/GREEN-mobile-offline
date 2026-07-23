import 'package:flutter_test/flutter_test.dart';
import 'package:green_app/utils/date_formatter.dart';

void main() {
  // Use a local DateTime so toLocal() is a no-op and assertions are stable
  // regardless of the machine timezone.
  final date = DateTime(2026, 2, 3, 14, 5);

  group('formatDateFrench', () {
    test('formats with French month name and separator by default', () {
      expect(formatDateFrench(date), '3-février-2026 à 14:05');
    });

    test('uses English month names and separator for "en"', () {
      expect(formatDateFrench(date, 'en'), '3-February-2026 at 14:05');
    });

    test('uses pidgin separator with English month names', () {
      expect(formatDateFrench(date, 'pid'), '3-February-2026 for 14:05');
    });

    test('falls back to French for an unknown locale', () {
      expect(formatDateFrench(date, 'xx'), '3-février-2026 à 14:05');
    });

    test('pads hours and minutes to two digits', () {
      expect(formatDateFrench(DateTime(2026, 1, 9, 7, 3)),
          '9-janvier-2026 à 07:03');
    });
  });

  group('formatDateOnlyFrench', () {
    test('omits the time component', () {
      expect(formatDateOnlyFrench(date), '3-février-2026');
      expect(formatDateOnlyFrench(date, 'en'), '3-February-2026');
    });
  });

  group('formatTimeOnlyFrench', () {
    test('returns zero-padded HH:mm', () {
      expect(formatTimeOnlyFrench(date), '14:05');
      expect(formatTimeOnlyFrench(DateTime(2026, 1, 1, 0, 0)), '00:00');
    });
  });
}
