import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;

import '../rag_service.dart';
import '../storage/storage_service.dart';
import '../user_scope.dart';

/// Erreur affichable de GreenBot (sans détail technique).
class GreenBotException implements Exception {
  /// no-key | network | busy (modèles saturés) | quota | blocked | empty | unknown
  final String code;
  const GreenBotException(this.code);
  @override
  String toString() => 'GreenBotException($code)';
}

/// Résultat de la transcription d'un message vocal.
class VoiceTranscript {
  final String text;
  final bool inaudible;
  const VoiceTranscript(this.text, {this.inaudible = false});
}

/// Ce que l'appel à un modèle a rencontré, et ce qu'il faut en faire.
enum GeminiFailure {
  /// Modèle inconnu pour cette clé, ou option non prise en charge → modèle suivant.
  modelUnavailable,

  /// Modèle saturé (503 « high demand »), erreur serveur ou délai dépassé → modèle suivant.
  overloaded,

  /// Quota de la clé atteint (429) → modèle suivant (quotas par modèle).
  quota,

  /// Clé invalide ou refusée → arrêt.
  auth,

  /// Réponse bloquée par les filtres de sécurité → arrêt.
  blocked,

  /// Pas de réseau → arrêt.
  network,

  unknown,
}

/// GreenBot : conversation agricole via l'API Gemini, enrichie par la
/// recherche documentaire hors ligne (RAG BM25), et transcription des
/// messages vocaux.
///
/// Modèles vérifiés le 9 novembre 2026 avec la clé du projet (liste de
/// l'API + appels réels, voir CHANGELOG 2.1.0) :
/// - gemini-3.5-flash-lite : ~1 à 4 s, sans « réflexion » → premier choix ;
/// - gemini-3.5-flash : ~10 à 13 s, raisonne avant de répondre ;
/// - gemini-3.8-flash : souvent saturé (503 ou plus de 60 s).
/// Chaque modèle a [requestTimeout] pour répondre ; s'il est saturé,
/// introuvable ou hors quota, le suivant est essayé.
///
/// Les modèles 3.x « réfléchissent » avant de répondre et ces jetons de
/// réflexion comptent dans maxOutputTokens : avec 700 jetons (v2.0), une
/// réponse pouvait être coupée net (constaté : 284 jetons de réflexion
/// pour 12 de réponse avec un plafond de 300). Le plafond passe à 4096 ;
/// la longueur des réponses reste réglée par le prompt (3 à 5 phrases).
class GeminiService {
  static const defaultChatModels = ['gemini-3.5-flash-lite', 'gemini-3.5-flash', 'gemini-3.8-flash'];

  /// gemini-3.5-transcribe n'accepte pas d'instruction système : les modèles
  /// généralistes transcrivent et traduisent mieux à partir de la consigne.
  static const defaultAudioModels = ['gemini-3.5-flash-lite', 'gemini-3.5-flash', 'gemini-3.8-flash'];

  static const maxOutputTokens = 4096;

  /// Durée maximale d'un message vocal (WAV 16 kHz mono ≈ 3,8 Mo).
  static const maxVoiceDuration = Duration(minutes: 2);

  /// Client HTTP (injecté dans les tests ; null = client par défaut).
  final http.Client? httpClient;
  final Duration requestTimeout;

  String? _apiKey;
  List<String> _chatModels = defaultChatModels;
  List<String> _audioModels = defaultAudioModels;

  /// Dernier modèle ayant répondu et durée de l'appel (mesures, tests).
  String? lastModel;
  Duration? lastLatency;

  GeminiService({this.httpClient, this.requestTimeout = const Duration(seconds: 25)});

  bool get isConfigured => (_apiKey ?? '').isNotEmpty;
  List<String> get chatModels => List.unmodifiable(_chatModels);
  List<String> get audioModels => List.unmodifiable(_audioModels);

  void initialize(String apiKey, {String? chatModel, String? audioModel}) {
    _apiKey = apiKey.trim();
    _chatModels = defaultChatModels;
    _audioModels = defaultAudioModels;
    if (chatModel != null && chatModel.trim().isNotEmpty) {
      final m = chatModel.trim();
      _chatModels = [m, ...defaultChatModels.where((x) => x != m)];
    }
    if (audioModel != null && audioModel.trim().isNotEmpty) {
      final m = audioModel.trim();
      _audioModels = [m, ...defaultAudioModels.where((x) => x != m)];
    }
  }

  GenerativeModel _model(String name, String systemPrompt) => GenerativeModel(
        model: name,
        apiKey: _apiKey!,
        httpClient: httpClient,
        systemInstruction: Content.system(systemPrompt),
        generationConfig: GenerationConfig(temperature: 0.4, maxOutputTokens: maxOutputTokens),
        // Seuil « élevé seulement » : au seuil moyen (v2.0), des réponses
        // agricoles banales étaient bloquées comme « harcèlement » (mesuré le
        // 9 novembre 2026 : 1 réponse sur 2 à la question « feuilles de
        // manioc jaunes »), et la bibliothèque échouait sur la réponse vide.
        // Les garde-fous métier (pas de doses, pas de produits interdits)
        // sont dans la consigne système.
        safetySettings: [
          SafetySetting(HarmCategory.harassment, HarmBlockThreshold.high),
          SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.high),
          SafetySetting(HarmCategory.dangerousContent, HarmBlockThreshold.high),
        ],
      );

  /// Classe une erreur de l'API (testé sur les messages réels de Gemini).
  @visibleForTesting
  static GeminiFailure classify(Object e) {
    if (e is SocketException || e is http.ClientException || e is HandshakeException) return GeminiFailure.network;
    if (e is TimeoutException) return GeminiFailure.overloaded;
    if (e is InvalidApiKey) return GeminiFailure.auth;
    final msg = (e is GenerativeAIException ? e.message : '$e').toLowerCase();
    if (msg.contains('socketexception') || msg.contains('failed host lookup') || msg.contains('connection closed')) {
      return GeminiFailure.network;
    }
    if (msg.contains('not found') || msg.contains('is not supported') || msg.contains('not enabled for this model')) {
      return GeminiFailure.modelUnavailable;
    }
    // Réponse vide (candidat filtré : « Content: {} ») que la bibliothèque
    // ne sait pas lire : on retente avec le modèle suivant.
    if (msg.contains('unhandled format')) return GeminiFailure.overloaded;
    if (msg.contains('high demand') || msg.contains('overloaded') || msg.contains('unavailable') ||
        msg.contains('server error [5') || msg.contains('try again later') || msg.contains('internal error')) {
      return GeminiFailure.overloaded;
    }
    if (msg.contains('quota') || msg.contains('rate limit') || msg.contains('resource has been exhausted') ||
        msg.contains('resource_exhausted')) {
      return GeminiFailure.quota;
    }
    if (msg.contains('api key') || msg.contains('permission') || msg.contains('unauthenticated') ||
        msg.contains('api_key')) {
      return GeminiFailure.auth;
    }
    if (msg.contains('safety') || msg.contains('blocked')) return GeminiFailure.blocked;
    return GeminiFailure.unknown;
  }

  /// Appelle le premier modèle de [names] qui répond.
  Future<String> _generate(List<String> names, String systemPrompt, List<Content> contents) async {
    if (!isConfigured) throw const GreenBotException('no-key');
    final failures = <GeminiFailure>[];
    for (final name in names) {
      final watch = Stopwatch()..start();
      try {
        final res = await _model(name, systemPrompt).generateContent(contents).timeout(requestTimeout);
        final text = res.text?.trim();
        if (text == null || text.isEmpty) {
          // Réponse vide (réflexion qui a épuisé le budget, par ex.) : modèle suivant.
          failures.add(GeminiFailure.overloaded);
          continue;
        }
        lastModel = name;
        lastLatency = watch.elapsed;
        return text;
      } catch (e) {
        final f = classify(e);
        failures.add(f);
        final detail = '$e'.replaceAll(RegExp(r'\s+'), ' ');
        debugPrint('GreenBot : $name → ${f.name} (${watch.elapsed.inMilliseconds} ms) '
            '${detail.length > 240 ? '${detail.substring(0, 240)}…' : detail}');
        switch (f) {
          case GeminiFailure.modelUnavailable:
          case GeminiFailure.overloaded:
          case GeminiFailure.quota:
            continue;
          case GeminiFailure.auth:
            throw const GreenBotException('no-key');
          case GeminiFailure.blocked:
            throw const GreenBotException('blocked');
          case GeminiFailure.network:
            throw const GreenBotException('network');
          case GeminiFailure.unknown:
            continue;
        }
      }
    }
    if (failures.contains(GeminiFailure.quota) && !failures.contains(GeminiFailure.overloaded)) {
      throw const GreenBotException('quota');
    }
    if (failures.contains(GeminiFailure.overloaded)) throw const GreenBotException('busy');
    throw const GreenBotException('unknown');
  }

  String _ragContext(String query) {
    final hits = RagService.instance.search(query, topK: 3);
    if (hits.isEmpty) return '';
    return hits.map((c) => c.text.trim()).join('\n---\n');
  }

  String _systemPrompt({required String ragContext, required String language}) {
    final lang = switch (language) {
      'en' => 'anglais simple',
      'pid' => 'pidgin camerounais simple',
      _ => 'français simple',
    };
    return '''Tu es GREEN, l'assistant agricole de l'application GREEN (diagnostic des maladies des plantes par photo, puis conseils).

LANGUE : réponds en $lang.

COMMENT TU PARLES :
- Réponses courtes : 3 à 5 phrases, sauf si l'agriculteur demande plus de détails.
- Mots simples, sans jargon : beaucoup d'agriculteurs ont peu été à l'école.
- Concret : dis quoi faire, une étape à la fois, puis propose la suite par une question simple.
- Pas de mise en forme : pas de **, pas de #, pas de listes à tirets. Pour des étapes, numérote : "1. ... 2. ...".

APRÈS UN DIAGNOSTIC : 1) ce que la plante a, en une phrase ; 2) ce qui arrive si on ne fait rien ; 3) UNE première action accessible localement ; 4) demande s'il veut la suite.

PRUDENCE : une photo donne une maladie probable, pas une certitude. Ne donne jamais de dose de produit chimique ; conseille un produit homologué et l'avis d'un technicien agricole ou d'un vendeur agréé. Ne recommande aucun produit interdit.

DOCUMENTS : utilise d'abord les extraits ci-dessous s'ils répondent à la question. Sinon dis-le et donne un conseil prudent général ; n'invente aucun chiffre ni détail technique.
${ragContext.isEmpty ? '' : '\nEXTRAITS DE DOCUMENTS AGRONOMIQUES :\n$ragContext'}''';
  }

  /// Réponse de GreenBot à [message], en tenant compte des derniers échanges.
  Future<String> reply(
    String message, {
    List<({bool isUser, String text})> history = const [],
    String language = 'fr',
  }) async {
    final system = _systemPrompt(ragContext: _ragContext(message), language: language);
    // Les 8 derniers messages (v1 : les 5 PREMIERS, d'où des réponses qui
    // ignoraient la fin de la conversation).
    final recent = history.length > 8 ? history.sublist(history.length - 8) : history;
    // L'API exige une alternance utilisateur / modèle : les messages
    // consécutifs d'un même rôle (question restée sans réponse après une
    // coupure réseau, par exemple) sont fusionnés, et l'échange commence par
    // l'utilisateur.
    final turns = <({bool isUser, String text})>[];
    for (final m in [...recent, (isUser: true, text: message)]) {
      if (turns.isEmpty && !m.isUser) continue;
      if (turns.isNotEmpty && turns.last.isUser == m.isUser) {
        final last = turns.removeLast();
        turns.add((isUser: last.isUser, text: '${last.text}\n${m.text}'));
      } else {
        turns.add(m);
      }
    }
    final contents = [
      for (final m in turns) m.isUser ? Content.text(m.text) : Content.model([TextPart(m.text)]),
    ];
    return _stripMarkdown(await _generate(_chatModels, system, contents));
  }

  /// Conseil mis en cache par compte (fiche terrain → GreenBot).
  Future<String> adviceWithCache(String prompt, String cacheKey, {String language = 'fr'}) async {
    final key = 'advice_${UserScope.userId ?? 'guest'}_${language}_$cacheKey';
    final storage = StorageService();
    try {
      final cached = storage.getString(key);
      if (cached != null && cached.isNotEmpty) return cached;
    } catch (_) {}
    final answer = await reply(prompt, language: language);
    try {
      await storage.setString(key, answer);
    } catch (_) {}
    return answer;
  }

  /// Transcrit (et traduit si besoin) un message vocal WAV dans la langue
  /// de l'application. Le texte obtenu est ensuite envoyé à GreenBot comme
  /// un message écrit.
  Future<VoiceTranscript> transcribe(Uint8List wav, {String language = 'fr'}) async {
    final target = switch (language) {
      'en' => 'anglais',
      'pid' => 'pidgin camerounais',
      _ => 'français',
    };
    const marker = '[INAUDIBLE]';
    final system = '''Tu transcris les messages vocaux d'agriculteurs pour l'assistant GREEN.
Écris exactement ce que dit la personne, en $target. Si elle parle une autre langue (pidgin, langue locale camerounaise, anglais, français), traduis fidèlement en $target.
Corrige seulement les hésitations ("euh", répétitions). Ne réponds pas à la question, n'ajoute aucun commentaire, aucun guillemet.
Si l'audio est vide ou incompréhensible, écris exactement : $marker''';
    final text = await _generate(_audioModels, system, [
      Content.multi([
        TextPart('Transcris ce message vocal.'),
        DataPart('audio/wav', wav),
      ]),
    ]);
    final clean = text.replaceAll('"', '').trim();
    if (clean.isEmpty || clean.contains(marker)) return const VoiceTranscript('', inaudible: true);
    return VoiceTranscript(clean);
  }

  /// Filet de sécurité si le modèle utilise quand même du Markdown : le chat
  /// affiche du texte brut.
  static String _stripMarkdown(String text) {
    var out = text.replaceAllMapped(RegExp(r'\*\*(.*?)\*\*'), (m) => m.group(1) ?? '');
    out = out.replaceAllMapped(RegExp(r'(?<!\w)\*(\S.*?)\*(?!\w)'), (m) => m.group(1) ?? '');
    out = out.replaceAll(RegExp(r'^[ \t]*[-*•]\s+', multiLine: true), '');
    out = out.replaceAll(RegExp(r'^#{1,6}\s*', multiLine: true), '');
    return out.trim();
  }

  @visibleForTesting
  static String stripMarkdownForTest(String text) => _stripMarkdown(text);
}

final geminiService = GeminiService();
