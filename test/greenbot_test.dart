import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:green_app/services/gemini/gemini_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Tests hors ligne de GreenBot : l'API Gemini est simulée avec les formats
/// de réponse et les messages d'erreur RÉELS relevés le 9 novembre 2026.
/// Les tests en conditions réelles sont dans test/live/ (voir README).

String _ok(String text) => jsonEncode({
      'candidates': [
        {
          'content': {
            'role': 'model',
            'parts': [
              {'text': text}
            ]
          },
          'finishReason': 'STOP',
          'index': 0,
        }
      ],
      // Champs récents de l'API (3.x) : ne doivent pas casser l'analyse.
      'usageMetadata': {
        'promptTokenCount': 16,
        'candidatesTokenCount': 58,
        'totalTokenCount': 74,
        'thoughtsTokenCount': 0,
        'serviceTier': 'standard',
      },
      'modelVersion': 'gemini-3.5-flash-lite',
      'responseId': 'abc',
    });

http.Response _error(int code, String message, {String status = 'UNKNOWN', String? reason}) => _json(
      jsonEncode({
        'error': {
          'code': code,
          'message': message,
          'status': status,
          if (reason != null)
            'details': [
              {'@type': 'type.googleapis.com/google.rpc.ErrorInfo', 'reason': reason}
            ],
        }
      }),
      code,
    );

/// Réponse JSON en UTF-8, comme l'API réelle (http.Response(String) code en
/// latin-1 sans charset, ce que Gemini ne fait jamais).
http.Response _json(String body, int code) =>
    http.Response.bytes(utf8.encode(body), code, headers: {'content-type': 'application/json; charset=UTF-8'});

String _model(http.Request r) => r.url.pathSegments.last.split(':').first;

/// Client simulé : une réponse par modèle, et journal des requêtes.
class _FakeGemini {
  final Map<String, FutureOr<http.Response> Function(http.Request)> byModel;
  final requests = <http.Request>[];
  _FakeGemini(this.byModel);

  MockClient get client => MockClient((r) async {
        requests.add(r);
        final h = byModel[_model(r)];
        if (h == null) return _error(404, 'models/${_model(r)} is not found for API version v1beta', status: 'NOT_FOUND');
        return h(r);
      });

  Map<String, dynamic> body(int i) => jsonDecode(requests[i].body) as Map<String, dynamic>;
}

GeminiService _service(_FakeGemini fake, {Duration timeout = const Duration(seconds: 5)}) =>
    GeminiService(httpClient: fake.client, requestTimeout: timeout)..initialize('test-key');

void main() {
  group('Classement des erreurs Gemini (messages réels)', () {
    test('modèle saturé (503) → essayer le modèle suivant', () {
      expect(
        GeminiService.classify(GenerativeAIException(
            'Server Error [503]: {"error":{"code":503,"message":"This model is currently experiencing high demand. Spikes in demand are usually temporary. Please try again later.","status":"UNAVAILABLE"}}')),
        GeminiFailure.overloaded,
      );
      expect(GeminiService.classify(TimeoutException('25 s')), GeminiFailure.overloaded);
    });

    test('modèle inconnu ou consigne système refusée → modèle suivant', () {
      expect(GeminiService.classify(ServerException('models/gemini-9 is not found for API version v1beta')),
          GeminiFailure.modelUnavailable);
      expect(GeminiService.classify(ServerException('Developer instruction is not enabled for this model')),
          GeminiFailure.modelUnavailable);
    });

    test('réponse filtrée vide (« Content: {} ») → modèle suivant, pas d\'erreur affichée', () {
      expect(GeminiService.classify(Exception('Unhandled format for Content: {}')), GeminiFailure.overloaded);
    });

    test('quota, clé refusée, réseau, filtres', () {
      expect(GeminiService.classify(ServerException('Resource has been exhausted (e.g. check quota).')), GeminiFailure.quota);
      expect(GeminiService.classify(InvalidApiKey('API key not valid. Please pass a valid API key.')), GeminiFailure.auth);
      expect(GeminiService.classify(const SocketException('Failed host lookup')), GeminiFailure.network);
      expect(GeminiService.classify(http.ClientException('Connection closed')), GeminiFailure.network);
      expect(GeminiService.classify(ServerException('Candidate was blocked due to safety')), GeminiFailure.blocked);
    });
  });

  group('Réponses de GreenBot', () {
    test('réponse filtrée par sécurité sur un modèle → réponse du modèle suivant', () async {
      final fake = _FakeGemini({
        'gemini-3.5-flash-lite': (_) => _json(
            jsonEncode({
              'candidates': [
                {'content': {}, 'finishReason': 'SAFETY', 'index': 0}
              ]
            }),
            200),
        'gemini-3.5-flash': (_) => _json(_ok('Arrachez les plants malades.'), 200),
      });
      expect(await _service(fake).reply('Mes feuilles de manioc jaunissent'), 'Arrachez les plants malades.');
    });

    test('filtres de sécurité au seuil « élevé seulement » (pas de faux blocages)', () async {
      final fake = _FakeGemini({'gemini-3.5-flash-lite': (_) => _json(_ok('ok'), 200)});
      await _service(fake).reply('x');
      final settings = fake.body(0)['safetySettings'] as List;
      expect(settings, isNotEmpty);
      expect(settings.every((s) => s['threshold'] == 'BLOCK_ONLY_HIGH'), isTrue);
    });

    test('requête conforme : clé en en-tête, consigne système, plafond de jetons, langue', () async {
      final fake = _FakeGemini({'gemini-3.5-flash-lite': (_) => _json(_ok('Utilisez des boutures saines.'), 200)});
      final bot = _service(fake);
      final answer = await bot.reply('Que faire contre la mosaïque du manioc ?', language: 'fr');

      expect(answer, 'Utilisez des boutures saines.');
      expect(bot.lastModel, 'gemini-3.5-flash-lite');
      final r = fake.requests.single;
      expect(r.headers['x-goog-api-key'], 'test-key');
      expect(r.url.path, endsWith('models/gemini-3.5-flash-lite:generateContent'));
      final body = fake.body(0);
      expect(body['generationConfig']['maxOutputTokens'], GeminiService.maxOutputTokens);
      final system = (body['systemInstruction']['parts'] as List).first['text'] as String;
      expect(system, contains('français simple'));
      expect(system, contains('Ne donne jamais de dose'));
    });

    test('anglais et pidgin : la consigne suit la langue de l\'application', () async {
      final fake = _FakeGemini({'gemini-3.5-flash-lite': (_) => _json(_ok('OK'), 200)});
      final bot = _service(fake);
      await bot.reply('Hello', language: 'en');
      await bot.reply('How far', language: 'pid');
      expect((fake.body(0)['systemInstruction']['parts'] as List).first['text'], contains('anglais simple'));
      expect((fake.body(1)['systemInstruction']['parts'] as List).first['text'], contains('pidgin camerounais'));
    });

    test('modèle saturé → bascule automatique sur le suivant', () async {
      final fake = _FakeGemini({
        'gemini-3.5-flash-lite': (_) => http.Response(
            '{"error":{"code":503,"message":"This model is currently experiencing high demand.","status":"UNAVAILABLE"}}', 503),
        'gemini-3.5-flash': (_) => _json(_ok('Réponse du second modèle.'), 200),
      });
      final bot = _service(fake);
      expect(await bot.reply('Bonjour'), 'Réponse du second modèle.');
      expect(bot.lastModel, 'gemini-3.5-flash');
      expect(fake.requests.map(_model), ['gemini-3.5-flash-lite', 'gemini-3.5-flash']);
    });

    test('modèle trop lent → délai dépassé, modèle suivant', () async {
      final fake = _FakeGemini({
        'gemini-3.5-flash-lite': (_) => Future.delayed(const Duration(milliseconds: 300), () => _json(_ok('trop tard'), 200)),
        'gemini-3.5-flash': (_) => _json(_ok('à temps'), 200),
      });
      final bot = _service(fake, timeout: const Duration(milliseconds: 100));
      expect(await bot.reply('Bonjour'), 'à temps');
    });

    test('modèle choisi dans .env essayé en premier, les autres en secours', () async {
      final fake = _FakeGemini({'gemini-3.8-flash': (_) => _json(_ok('3.8'), 200)});
      final bot = GeminiService(httpClient: fake.client)..initialize('k', chatModel: 'gemini-3.8-flash');
      expect(bot.chatModels.first, 'gemini-3.8-flash');
      expect(bot.chatModels.toSet(), GeminiService.defaultChatModels.toSet());
      expect(await bot.reply('x'), '3.8');
    });

    test('tous saturés → « busy » ; quotas épuisés → « quota »', () async {
      final busy = _FakeGemini({
        for (final m in GeminiService.defaultChatModels) m: (_) => http.Response('{"error":{"code":503,"message":"overloaded"}}', 503),
      });
      await expectLater(_service(busy).reply('x'), throwsA(isA<GreenBotException>().having((e) => e.code, 'code', 'busy')));

      final quota = _FakeGemini({
        for (final m in GeminiService.defaultChatModels)
          m: (_) => _error(429, 'Resource has been exhausted (e.g. check quota).', status: 'RESOURCE_EXHAUSTED'),
      });
      await expectLater(_service(quota).reply('x'), throwsA(isA<GreenBotException>().having((e) => e.code, 'code', 'quota')));
    });

    test('clé invalide → « no-key », sans essayer les autres modèles', () async {
      final fake = _FakeGemini({
        'gemini-3.5-flash-lite': (_) =>
            _error(400, 'API key not valid. Please pass a valid API key.', status: 'INVALID_ARGUMENT', reason: 'API_KEY_INVALID'),
      });
      await expectLater(_service(fake).reply('x'), throwsA(isA<GreenBotException>().having((e) => e.code, 'code', 'no-key')));
      expect(fake.requests, hasLength(1));
    });

    test('sans clé : erreur claire, aucun appel réseau', () async {
      final fake = _FakeGemini({});
      final bot = GeminiService(httpClient: fake.client);
      await expectLater(bot.reply('x'), throwsA(isA<GreenBotException>().having((e) => e.code, 'code', 'no-key')));
      expect(fake.requests, isEmpty);
    });

    test('hors ligne → « network »', () async {
      final bot = GeminiService(httpClient: MockClient((_) => throw const SocketException('Failed host lookup')))..initialize('k');
      await expectLater(bot.reply('x'), throwsA(isA<GreenBotException>().having((e) => e.code, 'code', 'network')));
    });

    test('mémoire : 8 derniers messages, rôles alternés, message en double fusionné', () async {
      final fake = _FakeGemini({'gemini-3.5-flash-lite': (_) => _json(_ok('ok'), 200)});
      final history = [
        for (var i = 0; i < 10; i++) (isUser: i.isEven, text: 'm$i'),
        (isUser: true, text: 'question restée sans réponse'),
      ];
      await _service(fake).reply('nouvelle question', history: history);
      final contents = fake.body(0)['contents'] as List;
      final roles = contents.map((c) => c['role']).toList();
      for (var i = 1; i < roles.length; i++) {
        expect(roles[i], isNot(roles[i - 1]), reason: 'alternance user/model');
      }
      expect(roles.first, 'user');
      expect(roles.last, 'user');
      final last = (contents.last['parts'] as List).first['text'] as String;
      expect(last, contains('question restée sans réponse'));
      expect(last, contains('nouvelle question'));
      expect(jsonEncode(contents), isNot(contains('"m0"')), reason: 'messages anciens écartés');
    });

    test('Markdown retiré de la réponse affichée', () async {
      final fake = _FakeGemini({
        'gemini-3.5-flash-lite': (_) => _json(_ok('## Conseil\n- **Arrachez** les plants\n- *Brûlez* les feuilles'), 200),
      });
      final answer = await _service(fake).reply('x');
      expect(answer, isNot(contains('**')));
      expect(answer, isNot(contains('#')));
      expect(answer, contains('Arrachez les plants'));
    });
  });

  group('Messages vocaux', () {
    final wav = Uint8List.fromList(List.generate(64, (i) => i));

    test('le son est envoyé en audio/wav avec la consigne de transcription', () async {
      final fake = _FakeGemini({'gemini-3.5-flash-lite': (_) => _json(_ok('"Mes feuilles de manioc jaunissent"'), 200)});
      final t = await _service(fake).transcribe(wav, language: 'fr');
      expect(t.inaudible, isFalse);
      expect(t.text, 'Mes feuilles de manioc jaunissent');
      final parts = (fake.body(0)['contents'] as List).first['parts'] as List;
      final inline = parts.firstWhere((p) => (p as Map).containsKey('inlineData'))['inlineData'];
      expect(inline['mimeType'], 'audio/wav');
      expect(base64Decode(inline['data'] as String), wav);
      expect((fake.body(0)['systemInstruction']['parts'] as List).first['text'], contains('traduis fidèlement en français'));
    });

    test('audio incompréhensible → signalé, rien n\'est envoyé à GreenBot', () async {
      final fake = _FakeGemini({'gemini-3.5-flash-lite': (_) => _json(_ok('[INAUDIBLE]'), 200)});
      final t = await _service(fake).transcribe(wav);
      expect(t.inaudible, isTrue);
      expect(t.text, isEmpty);
    });

    test('chaîne complète : vocal → texte → réponse', () async {
      final fake = _FakeGemini({
        'gemini-3.5-flash-lite': (r) {
          final hasAudio = r.body.contains('inlineData');
          return _json(_ok(hasAudio ? 'Mon maïs a des feuilles jaunes' : 'Vérifiez l\'azote du sol.'), 200);
        },
      });
      final bot = _service(fake);
      final t = await bot.transcribe(wav, language: 'fr');
      final answer = await bot.reply(t.text, language: 'fr');
      expect(answer, 'Vérifiez l\'azote du sol.');
      expect(fake.requests, hasLength(2));
      expect(fake.requests.last.body, contains('Mon maïs a des feuilles jaunes'));
    });
  });
}
