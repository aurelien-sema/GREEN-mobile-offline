import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:green_app/l10n/app_strings.dart';

/// Toutes les clés utilisées dans le code existent en français et en
/// anglais, avec les mêmes paramètres {…}.
void main() {
  final used = <String>{};
  final patterns = [
    RegExp(r"\bt\(\s*'([A-Za-z][A-Za-z0-9_]*)'\s*\)"),
    RegExp(r"\btf\(\s*'([A-Za-z][A-Za-z0-9_]*)'"),
    RegExp(r"\?\s*'([a-z][A-Za-z0-9_]*)'\s*:\s*'([a-z][A-Za-z0-9_]*)'"),
  ];
  for (final f in Directory('lib').listSync(recursive: true).whereType<File>()) {
    if (!f.path.endsWith('.dart') || f.path.contains('l10n')) continue;
    // Les commentaires ne comptent pas (exemples dans la documentation).
    final src = f.readAsLinesSync().where((l) => !l.trimLeft().startsWith('//')).join('\n');
    for (final p in patterns) {
      for (final m in p.allMatches(src)) {
        for (var g = 1; g <= m.groupCount; g++) {
          final k = m.group(g);
          if (k != null) used.add(k);
        }
      }
    }
  }
  // Clés construites dynamiquement.
  used.addAll(['secQ1', 'secQ2', 'secQ3', 'secQ4']);
  used.addAll(['fungal', 'oomycete', 'bacterial', 'viral', 'pest', 'nematode', 'physiological', 'healthy'].map((t) => 'type_$t'));
  // Codes internes utilisés dans des ternaires, qui ne sont pas des clés.
  used.removeAll(['offline', 'timeout', 'unauthorized', 'camera', 'gallery', 'remove', 'delete', 'clear',
    'dark', 'light', 'fr', 'en', 'text', 'voice', 'server']);

  for (final locale in ['fr', 'en']) {
    test('toutes les clés utilisées existent en $locale', () {
      final keys = AppStrings.keysFor(locale);
      final missing = used.where((k) => !keys.contains(k)).toList()..sort();
      expect(missing, isEmpty);
    });
  }

  test('mêmes paramètres {…} en français et en anglais', () {
    final param = RegExp(r'\{(\w+)\}');
    for (final k in used) {
      final fr = param.allMatches(AppStrings.get(k, 'fr')).map((m) => m.group(1)).toSet();
      final en = param.allMatches(AppStrings.get(k, 'en')).map((m) => m.group(1)).toSet();
      expect(fr, en, reason: k);
    }
  });

  test('mention de l\'équipe dans À propos, sans niveau d\'études', () {
    final fr = AppStrings.get('teamDescription', 'fr');
    expect(fr, contains('Génie Informatique et Sciences de Données et Intelligence Artificielle'));
    expect(fr.toLowerCase(), isNot(contains('niveau')));
    expect(AppStrings.get('teamDescription', 'en').toLowerCase(), isNot(contains('level')));
  });
}
