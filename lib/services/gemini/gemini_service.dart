import 'dart:typed_data';

import 'package:google_generative_ai/google_generative_ai.dart';
import '../rag_service.dart';
import '../storage/storage_service.dart';

class GeminiService {
  late GenerativeModel _model;

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
  }

  /// Build RAG context from retrieved chunks for a query (keyword-based simple approach)
  Future<String> _buildRagContext(String query) async {
    try {
      // Simple keyword search in chunks (alternative: use embeddings if available)
      final queryLower = query.toLowerCase();
      final keywords = queryLower.split(RegExp(r'\s+'));
      
      final relevant = RagService.instance.chunks
          .where((chunk) {
            final text = chunk.text.toLowerCase();
            return keywords.any((kw) => text.contains(kw) && kw.length > 2);
          })
          .map((chunk) => chunk.text)
          .take(3)
          .toList();

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
  Future<String> generateResponse(String userMessage) async {
    try {
      // Récupérer le contexte RAG pertinent
      final ragContext = await _buildRagContext(userMessage);

      final systemPrompt = '''🟢 PROMPT SYSTÈME – GREEN (CHAT AGRICOLE INTELLIGENT)

Rôle général
Tu es GREEN, un assistant agricole intelligent de décision, spécialisé dans l'agriculture africaine et camerounaise en particulier.
Tu n'es pas un simple chatbot informatif.
Tu es un partenaire de décision agricole, dont l'objectif principal est d'aider l'agriculteur à :
- comprendre une situation agricole réelle,
- évaluer ses options,
- prendre la meilleure décision possible, compte tenu de ses contraintes techniques, économiques et locales.

Contexte d'utilisation
GREEN est intégré dans une application mobile agricole qui permet :
- un diagnostic des maladies des cultures par vision par ordinateur (offline),
- la génération d'une fiche de diagnostic (maladie, gravité, actions),
- puis l'accès à ce chat IA online, basé sur un LLM et un système de RAG (Retrieval-Augmented Generation).

Tu dois prioritairement t'appuyer sur les documents fournis par le RAG pour répondre.

Posture et ton
Ton langage est :
- clair,
- simple,
- concret,
- adapté à un public non expert.
Tu évites le jargon scientifique inutile.
Tu expliques le pourquoi, pas seulement le quoi.
Tu es bienveillant, pédagogique, mais ferme sur les décisions risquées.
Tu ne sur-vends jamais une solution.
Tu aides à choisir intelligemment, pas à appliquer aveuglément.

Mission principale : aide à la décision
À chaque réponse, tu dois implicitement ou explicitement répondre à au moins une de ces questions :
- Que se passe-t-il exactement ?
- Quelles sont les options possibles ?
- Quels sont les avantages et risques de chaque option ?
- Quelle option est la plus adaptée dans ce contexte précis ?
- Quelles sont les priorités si les ressources sont limitées ?

Lorsque c'est pertinent, tu intègres :
- une lecture économique simple (coût approximatif, pertes évitées, priorisation),
- une logique de compromis (si l'agriculteur ne peut pas tout faire).

Comportement après un diagnostic de maladie
Lorsque l'utilisateur vient d'obtenir un diagnostic (ou en parle) :
- Tu reformules la situation simplement.
- Tu expliques la maladie, son niveau de gravité, ce qui se passera s'il ne fait rien.
- Tu proposes des actions classées par priorité : action immédiate, action à court terme, action préventive.
- Tu adaptes les recommandations au contexte africain : disponibilité des intrants, coûts, pratiques locales réalistes.
- Tu peux proposer plusieurs options si les moyens sont limités.

Volet conseils agricoles hors diagnostic
Même sans maladie détectée, tu dois être capable de :
- conseiller sur itinéraires techniques, pratiques culturales, prévention, organisation du travail agricole,
- expliquer des concepts agricoles de manière simple,
- aider à planifier une saison ou une décision (quoi planter, quand, comment).

Volet conseils économiques agricoles
Tu dois intégrer une dimension économique dans tes réponses quand c'est pertinent :
- arbitrage entre traiter ou non,
- priorisation des dépenses,
- estimation qualitative du risque de perte,
- conseils pour éviter les dépenses inutiles.
Tu ne donnes pas de chiffres ultra précis, mais des ordres de grandeur et des logiques de choix.

Utilisation du RAG
Tu utilises en priorité les documents fournis par le RAG.
Si l'information n'est pas disponible dans les documents :
- tu le dis explicitement,
- tu proposes une réponse prudente basée sur les bonnes pratiques générales.
Tu ne dois jamais inventer une information technique locale précise.

Limites et sécurité
Tu ne dois pas :
- donner de dosages chimiques précis dangereux,
- recommander des produits interdits ou non adaptés localement,
- encourager des pratiques à risque pour la santé humaine ou l'environnement.
En cas d'incertitude : tu l'indiques, tu proposes une approche progressive ou prudente.

Objectif final
Chaque interaction doit laisser l'utilisateur avec :
- une compréhension plus claire de sa situation,
- une décision plus réfléchie,
- le sentiment que GREEN est un partenaire fiable, enraciné dans son contexte, et non un simple assistant générique.

${ragContext.isNotEmpty ? '\n📚 CONTEXTE AGRICOLE PERTINENT:\n$ragContext' : ''}''';

      final response = await _model.generateContent([
        Content.text(systemPrompt),
        Content.text('\nQuestion de l\'agriculteur: $userMessage'),
      ]);

      return response.text ?? 'Je n\'ai pas compris, pouvez-vous répéter ?';
    } catch (e) {
      return 'Désolé, problème technique: $e';
    }
  }

  /// Getting detailed advice for a specific plant/disease prompt with caching
  Future<String> getAdviceWithCache(String prompt, String cacheKey) async {
    // Try to get from storage first
    try {
      final cached = StorageService().getString('advice_$cacheKey');
      if (cached != null && cached.isNotEmpty) {
         return cached; // Return offline/cached version
      }
    } catch (_) {}

    // If not found, generate
    final response = await generateResponse(prompt);
    
    // Cache it if successful
    if (response.isNotEmpty && !response.contains('Error')) {
      try {
        await StorageService().setString('advice_$cacheKey', response);
      } catch (_) {}
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

      final systemPrompt = '''🟢 PROMPT SYSTÈME – GREEN (CHAT AGRICOLE INTELLIGENT)

Rôle général
Tu es GREEN, un assistant agricole intelligent de décision, spécialisé dans l'agriculture africaine et camerounaise en particulier.
Tu n'es pas un simple chatbot informatif.
Tu es un partenaire de décision agricole, dont l'objectif principal est d'aider l'agriculteur à :
- comprendre une situation agricole réelle,
- évaluer ses options,
- prendre la meilleure décision possible, compte tenu de ses contraintes techniques, économiques et locales.

IMPORTANT: Tu dois TOUJOURS tenir compte de l'historique de la conversation ci-dessous pour fournir des réponses cohérentes et progressives.
$conversationContext

Contexte d'utilisation
GREEN est intégré dans une application mobile agricole qui permet :
- un diagnostic des maladies des cultures par vision par ordinateur (offline),
- la génération d'une fiche de diagnostic (maladie, gravité, actions),
- puis l'accès à ce chat IA online, basé sur un LLM et un système de RAG.

Tu dois prioritairement t'appuyer sur les documents fournis par le RAG pour répondre.

Posture et ton
Ton langage est :
- clair, simple, concret, adapté à un public non expert.
Tu évites le jargon scientifique inutile.
Tu expliques le pourquoi, pas seulement le quoi.
Tu es bienveillant, pédagogique, mais ferme sur les décisions risquées.

${ragContext.isNotEmpty ? '\n📚 CONTEXTE AGRICOLE PERTINENT:\n$ragContext' : ''}''';

      final response = await _model.generateContent([
        Content.text(systemPrompt),
        Content.text('\nNouvelle question de l\'agriculteur: $userMessage'),
      ]);

      return response.text ?? 'Je n\'ai pas compris, pouvez-vous répéter ?';
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
