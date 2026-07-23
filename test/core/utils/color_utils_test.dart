import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:green_app/core/utils/color_utils.dart';

void main() {
  group('colorWithOpacity', () {
    test('preserves RGB channels and applies the given opacity', () {
      const source = Color.fromRGBO(46, 139, 87, 1.0);
      final result = colorWithOpacity(source, 0.5);
      expect((result.r * 255).round(), 46);
      expect((result.g * 255).round(), 139);
      expect((result.b * 255).round(), 87);
      expect(result.a, closeTo(0.5, 0.01));
    });

    test('opacity 0 yields a fully transparent color', () {
      final result = colorWithOpacity(Colors.red, 0.0);
      expect(result.a, 0.0);
    });

    test('opacity 1 yields a fully opaque color preserving channels', () {
      const source = Color.fromRGBO(33, 150, 243, 0.2);
      final result = colorWithOpacity(source, 1.0);
      expect(result.a, 1.0);
      expect((result.r * 255).round(), 33);
      expect((result.g * 255).round(), 150);
      expect((result.b * 255).round(), 243);
    });
  });
}
