import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:green_app/core/app_info.dart';

void main() {
  test('AppInfo correspond à la version de pubspec.yaml', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final match = RegExp(r'^version:\s*(\S+)\+(\d+)', multiLine: true).firstMatch(pubspec);
    expect(match, isNotNull, reason: 'ligne version: introuvable');
    expect(AppInfo.version, match!.group(1));
    expect(AppInfo.buildNumber, int.parse(match.group(2)!));
  });

  test('le code de version Android a augmenté depuis la v2.0 (2.0.0+2)', () {
    expect(AppInfo.buildNumber, greaterThan(2));
  });
}
