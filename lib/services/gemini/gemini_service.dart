import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../rag_service.dart';
import '../storage/storage_service.dart';
import '../user_scope.dart';

class GeminiService {
  late GenerativeModel _model;
  GenerativeModel? _embeddingModel;

  /// Doit rester identique au modèle utilisé pour construire
  /// assets/rag/embeddings_f32.bin (voir tools/rag/build_embeddings.py) —
  /// requête et documents doivent vivre dans le même espace vectoriel.
  static const String _embeddingModelName = 'models/text-embedding-004';

  /// Initialiser le service Gemini avec une clé API
  /// Vous devez obtenir une clé API gratuite depuis https://makersuite.google.com/app/apikey
  void initialize(String apiKey) {
    _model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: apiKey,
      safetySettings: [
        SafetySetting(HarmCategory.harassment, HarmBlockThreshold.medium),
        SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.medium),
      ],
    );
    // Même clé API, modèle dédié à l'embedding (utilisé pour le RAG sémantique).
    _embeddingModel = GenerativeModel(model: _embeddingModelName, apiKey: apiKey);
  }

  /// Recherche par similarité sémantique (embeddings) dans les chunks RAG.
  /// Retourne null si indisponible (RAG non initialisé, dimension
  /// incompatible, pas de clé/erreur réseau) pour laisser l'appelant se
  /// replier sur la recherche par mots-clés.
  Future<List<Map<String, dynamic>>?> _searchRagByEmbedding(String query, {int topK = 5}) async {
    if (_embeddingModel == null) return null;
    if (!RagService.instance.embeddingsUsable) return null;

    try {
      final response = await _embeddingModel!.embedContent(
        Content.text(query),
        taskType: TaskType.retrievalQuery,
      );
      final values = response.embedding.values;
      final results = await RagService.instance.searchByEmbedding(values, topK: topK);
      return results.isEmpty ? null : results;
    } catch (e) {
      debugPrint('GeminiService: recherche RAG par embedding indisponible ($e), repli mots-clés.');
      return null;
    }
  }

  /// Recherche par mots-clés (repli utilisé si la recherche sémantique n'est
  /// pas disponible ou échoue).
  List<String> _searchRagByKeywords(String query, {int limit = 3}) {
    final queryLower = query.toLowerCase();
    final keywords = queryLower.split(RegExp(r'\s+'));

    return RagService.instance.chunks
        .where((chunk) {
          final text = chunk.text.toLowerCase();
          return keywords.any((kw) => text.contains(kw) && kw.length > 2);
        })
        .map((chunk) => chunk.text)
        .take(limit)
        .toList();
  }

  /// Build RAG context from retrieved chunks for a query : recherche
  /// sémantique par embeddings en priorité, repli sur la recherche par
  /// mots-clés si indisponible.
  Future<String> _buildRagContext(String query) async {
    try {
      List<String> relevant;

      final semanticResults = await _searchRagByEmbedding(query, topK: 3);
      if (semanticResults != null) {
        relevant = semanticResults.map((r) => r['text'] as String).toList();
      } else {
        relevant = _searchRagByKeywords(query, limit: 3);
      }

      if (relevant.isEmpty) {
        return '';
      }
      return 'Contexte agricole et agronomique pertinent:\n\n${relevant.join('\n\n---\n\n')}\n\n';
    } catch (e) {
      // Si RAG échoue, on continue sans contexte
      return '';
    }
  }

  /// Envoyer un message et obtenir une réponse du bot Green avec contexte RAG
  /// Prompt système commun à [generateResponse] et [generateResponseWithContext].
  ///
  /// Réécrit pour privilégier des réponses courtes, directes et progressives
  /// (une étape à la fois plutôt qu'un pavé de conseils d'un coup), en
  /// langage très simple — le public cible vit en milieu rural, souvent avec
  /// peu d'éducation formelle : tout doit rester concret et terre-à-terre,
  /// sans jargon ni tournures abstraites.
  String _buildSystemPrompt({required String ragContext, String conversationContext = ''}) {
    return '''Tu es GREEN, l'assistant agricole de l'application Green (diagnostic des maladies des plantes par photo, puis conseils par chat).

COMMENT TU PARLES (règles strictes) :
- Réponses COURTES : 3 à 5 phrases maximum, sauf si l'agriculteur demande plus de détails.
- Langage TRÈS SIMPLE, comme si tu parlais à quelqu'un qui n'a pas beaucoup été à l'école. Pas de mots compliqués, pas de jargon scientifique.
- Direct et concret : va droit au but, dis quoi faire, pas de grands discours.
- PROGRESSIF : donne une seule étape ou un seul conseil à la fois. Termine par une question simple ou une proposition ("Tu veux que je t'explique comment faire ?") plutôt que de tout déballer en une fois.
- Terre-à-terre : parle de choses concrètes (le champ, la plante, l'argent, le temps), pas de théorie.
- N'utilise JAMAIS de symboles de mise en forme (pas de **, pas de *, pas de tirets "-" pour des listes, pas de titres avec #). Écris des phrases normales. Si tu dois faire une liste d'étapes, numérote-les simplement : "1. ... 2. ... 3. ..."
$conversationContext
QUAND TU RÉPONDS APRÈS UN DIAGNOSTIC :
1. Dis en une phrase simple ce que la plante a.
2. Dis en une phrase ce qui va se passer si on ne fait rien.
3. Propose UNE seule action à faire en premier (la plus urgente et la plus accessible localement).
4. Demande si l'agriculteur veut la suite des conseils.

CONSEILS ÉCONOMIQUES : si utile, dis simplement si ça vaut le coup de dépenser ou d'attendre — pas de chiffres précis, juste "c'est peu cher" / "ça coûte plus cher, réfléchis avant".

RAG : utilise en priorité les informations ci-dessous si présentes. Si l'info n'y est pas, dis-le simplement et donne un conseil prudent général — n'invente jamais un détail technique précis.

SÉCURITÉ : ne donne jamais de dosage chimique précis, ne recommande pas de produit dangereux ou interdit.
${ragContext.isNotEmpty ? '\n📚 INFOS UTILES:\n$ragContext' : ''}''';
  }

  /// Filet de sécurité si le modèle utilise quand même des symboles markdown
  /// (**gras**, listes à tirets/étoiles, titres #) malgré la consigne du
  /// prompt système — le chat affiche du texte brut (AnimatedChatMessage),
  /// donc ces symboles s'afficheraient sinon littéralement à l'écran.
  String _stripMarkdown(String text) {
    var out = text.replaceAllMapped(RegExp(r'\*\*(.*?)\*\*'), (m) => m.group(1) ?? '');
    out = out.replaceAll(RegExp(r'^[ \t]*[-*]\s+', multiLine: true), '');
    out = out.replaceAll(RegExp(r'^#{1,6}\s*', multiLine: true), '');
    return out.trim();
  }

  Future<String> generateResponse(String userMessage) async {
    try {
      final ragContext = await _buildRagContext(userMessage);
      final systemPrompt = _buildSystemPrompt(ragContext: ragContext);

      final response = await _model.generateContent([
        Content.text(systemPrompt),
        Content.text('\nQuestion de l\'agriculteur: $userMessage'),
      ]);

      final text = response.text;
      if (text == null) return 'Je n\'ai pas compris, pouvez-vous répéter ?';
      return _stripMarkdown(text);
    } catch (e) {
      return 'Désolé, problème technique: $e';
    }
  }

  /// Getting detailed advice for a specific plant/disease prompt with caching
  Future<String> getAdviceWithCache(String prompt, String cacheKey) async {
    // Clé préfixée par l'utilisateur courant : deux comptes sur le même
    // appareil ne doivent pas voir les conseils mis en cache l'un de l'autre.
    final storageKey = 'advice_${UserScope.userId ?? 'guest'}_$cacheKey';

    // Try to get from storage first
    try {
      final cached = StorageService().getString(storageKey);
      if (cached != null && cached.isNotEmpty) {
         return cached; // Return offline/cached version
      }
    } catch (e) {
      // Un cache illisible ne doit pas bloquer la génération, mais on trace
      // l'erreur au lieu de la masquer complètement.
      debugPrint('GeminiService: lecture du cache échouée pour $storageKey: $e');
    }

    // If not found, generate
    final response = await generateResponse(prompt);

    // Cache it if successful
    if (response.isNotEmpty && !response.contains('Error')) {
      try {
        await StorageService().setString(storageKey, response);
      } catch (e) {
        debugPrint('GeminiService: écriture du cache échouée pour $storageKey: $e');
      }
    }
    return response;
  }

  /// Generate response with chat context awareness
  Future<String> generateResponseWithContext(String userMessage, List<Map<String, dynamic>> chatHistory) async {
    try {
      // Récupérer le contexte RAG pertinent
      final ragContext = await _buildRagContext(userMessage);

      // Construire un historique pour le contexte
      String conversationContext = '';
      if (chatHistory.isNotEmpty) {
        conversationContext = 'Historique de la conversation:\n';
        for (var i = 0; i < chatHistory.length && i < 5; i++) {
          final msg = chatHistory[i];
          final role = msg['role'] == 'user' ? 'Agriculteur' : 'GREEN';
          conversationContext += '$role: ${msg['content']}\n';
        }
        conversationContext += '\nTiens compte de cet historique pour répondre de manière cohérente et progressive.\n';
      }

      final systemPrompt = _buildSystemPrompt(
        ragContext: ragContext,
        conversationContext: conversationContext.isNotEmpty
            ? '\nHISTORIQUE RÉCENT (reste cohérent avec ce qui a déjà été dit, ne répète pas) :\n$conversationContext'
            : '',
      );

      final response = await _model.generateContent([
        Content.text(systemPrompt),
        Content.text('\nNouvelle question de l\'agriculteur: $userMessage'),
      ]);

      final text = response.text;
      if (text == null) return 'Je n\'ai pas compris, pouvez-vous répéter ?';
      return _stripMarkdown(text);
    } catch (e) {
      return 'Désolé, problème technique: $e';
    }
  }

  /// Analyser une image de plante avec contexte RAG
  Future<String> analyzePlantImage(List<int> imageBytes) async {
    try {
      final systemPrompt = '''Regarde cette photo de plante pour un agriculteur.
Dis-moi simplement :
1. C'est quelle plante ?
2. Est-ce qu'elle est malade ou en bonne santé ?
3. Que doit faire l'agriculteur ? (Conseils simples et pratiques)

Parle comme un expert agronome qui explique à un cultivateur de village.
Utilise des mots simples.''';

      final response = await _model.generateContent([
        Content.multi([
          TextPart(systemPrompt),
          DataPart('image/jpeg', Uint8List.fromList(imageBytes)),
        ]),
      ]);

      return response.text ?? 'Je ne vois pas bien l\'image.';
    } catch (e) {
      return 'Erreur d\'analyse: $e';
    }
  }

  /// Obtenir des conseils sur les soins des plantes avec contexte RAG
  Future<String> getPlantCareAdvice(String plantName) async {
    try {
      // Récupérer le contexte RAG pour cette plante
      final ragContext = await _buildRagContext('conseils soins $plantName agronomie culture');

      final systemPrompt = '''Donne des conseils simples pour cultiver "$plantName".
Explique comment arroser, quand planter, et comment protéger la plante.
Langage simple, maximum 3-4 phrases, conseils PRATIQUES locaux.

${ragContext.isNotEmpty ? 'Ressources: $ragContext' : ''}''';

      final response = await _model.generateContent([
        Content.text(systemPrompt),
      ]);

      return response.text ?? 'Pas de conseils trouvés.';
    } catch (e) {
      return 'Erreur: $e';
    }
  }

  /// Identify disease from plant image with RAG agricultural context
  Future<String> identifyPlantDisease(List<int> imageBytes) async {
    try {
      final systemPrompt = '''Analyse cette plante malade rapidement.
Dis en 2-3 phrases :
1. La maladie (nom simple)
2. Symptômes visibles
3. Traitement simple et accessible localement

Parle français paysan, sois direct.''';

      final response = await _model.generateContent([
        Content.multi([
          TextPart(systemPrompt),
          DataPart('image/jpeg', Uint8List.fromList(imageBytes)),
        ]),
      ]);

      return response.text ?? 'Je ne reconnais pas la maladie.';
    } catch (e) {
      return 'Erreur: $e';
    }
  }
}

// Instance singleton
final geminiService = GeminiService();
