@Tags(['live'])
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:green_app/services/gemini/gemini_service.dart';
import 'package:green_app/services/green_web/green_web_client.dart';
import 'package:green_app/services/green_web/shared_web_account.dart';
import 'package:http/http.dart' as http;

/// Tests en conditions réelles : vraie clé Gemini, vrai serveur GREEN Web.
/// Ignorés par `flutter test` ; à lancer avant une version :
///
///   GREEN_LIVE=1 flutter test test/live --tags live
///
/// Les clés sont lues dans assets/.env (jamais dans le code ni dans la sortie).
/// Chaque test affiche une ligne « KPI » (modèle, durée) reprise dans le
/// CHANGELOG.
Map<String, String> _env() {
  final f = File('assets/.env');
  if (!f.existsSync()) return const {};
  final out = <String, String>{};
  for (final line in f.readAsLinesSync()) {
    final l = line.trim();
    if (l.isEmpty || l.startsWith('#') || !l.contains('=')) continue;
    final i = l.indexOf('=');
    out[l.substring(0, i).trim()] = l.substring(i + 1).trim();
  }
  return out;
}

void main() {
  final enabled = Platform.environment['GREEN_LIVE'] == '1';
  final env = _env();
  final key = env['GEMINI_API_KEY'] ?? '';
  final skipBot = !enabled ? 'GREEN_LIVE=1 non défini' : (key.isEmpty ? 'GEMINI_API_KEY absent de assets/.env' : null);

  late GeminiService bot;
  final client = http.Client();
  setUpAll(() {
    bot = GeminiService(httpClient: client, requestTimeout: const Duration(seconds: 30))
      ..initialize(key, chatModel: env['GEMINI_MODEL'], audioModel: env['GEMINI_AUDIO_MODEL']);
  });
  tearDownAll(client.close);

  void kpi(String what) =>
      // ignore: avoid_print
      print('KPI GreenBot | $what | modèle=${bot.lastModel} | ${bot.lastLatency?.inMilliseconds} ms');

  group('GreenBot (API Gemini réelle)', () {
    test('répond en français simple, sans Markdown', () async {
      final a = await bot.reply('Les feuilles de mon manioc sont jaunes et déformées. Que faire ?', language: 'fr');
      kpi('réponse FR');
      expect(a.length, inInclusiveRange(40, 1500));
      expect(a, isNot(contains('**')));
      expect(a.toLowerCase(), anyOf(contains('manioc'), contains('bouture'), contains('feuille')));
    }, skip: skipBot);

    test('répond en anglais quand l\'application est en anglais', () async {
      final a = await bot.reply('My tomato leaves have brown spots. What should I do first?', language: 'en');
      kpi('réponse EN');
      expect(a.toLowerCase(), anyOf(contains('the'), contains('leaves'), contains('remove')));
    }, skip: skipBot);

    test('garde le fil de la conversation', () async {
      final a = await bot.reply(
        'Rappelle-moi en un mot quelle culture je cultive.',
        history: const [
          (isUser: true, text: 'Je cultive du maïs à Bafoussam.'),
          (isUser: false, text: 'Très bien, comment puis-je vous aider pour votre maïs ?'),
        ],
      );
      kpi('mémoire');
      expect(a.toLowerCase(), contains('maïs'));
    }, skip: skipBot);

    test('message vocal réel : transcription puis réponse', () async {
      final wav = File('test/fixtures/voice_fr.wav');
      if (!wav.existsSync()) markTestSkipped('test/fixtures/voice_fr.wav absent');
      final t = await bot.transcribe(wav.readAsBytesSync(), language: 'fr');
      kpi('transcription');
      expect(t.inaudible, isFalse);
      expect(t.text.toLowerCase(), contains('manioc'));
      final a = await bot.reply(t.text, language: 'fr');
      kpi('réponse au vocal');
      expect(a, isNotEmpty);
    }, skip: skipBot);

    test('mauvaise clé → erreur « no-key » propre', () async {
      final bad = GeminiService(httpClient: client)..initialize('AIza-cle-invalide');
      await expectLater(bad.reply('x'), throwsA(isA<GreenBotException>().having((e) => e.code, 'code', 'no-key')));
    }, skip: skipBot);
  });

  group('Compte GREEN Web par défaut (serveur réel)', () {
    final creds = SharedAccountCredentials.fromEnv(env);
    final skipWeb = !enabled ? 'GREEN_LIVE=1 non défini' : (creds == null ? 'GREEN_WEB_* absents de assets/.env' : null);

    test('connexion du compte partagé et jeton valable plusieurs jours', () async {
      final web = GreenWebClient(httpClient: client, baseUrl: env['GREEN_API_BASE_URL']);
      final watch = Stopwatch()..start();
      final session = await web.login(creds!.identifier, creds.password);
      // ignore: avoid_print
      print('KPI GREEN Web | connexion | ${watch.elapsedMilliseconds} ms');
      final exp = SharedWebAccount.jwtExpiry(session.token);
      expect(exp, isNotNull);
      expect(exp!.difference(DateTime.now().toUtc()).inDays, greaterThanOrEqualTo(6));
      final me = await web.me(session.token);
      expect(me.id, session.user.id);
    }, skip: skipWeb);
  });
}
