import 'dart:typed_data';

import 'package:google_generative_ai/google_generative_ai.dart';
import '../rag_service.dart';

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

      final systemPrompt = '''Tu es Green Bot, un assistant IA spécialisé dans l'agriculture et l'agronomie.
Tu dois répondre de manière utile, précise et amicale en français.
Tu dois toujours te concentrer sur les sujets liés à l'agriculture, la culture des plantes, l'agronomie, les maladies des plantes et les pratiques agricoles.

${ragContext.isNotEmpty ? 'Utilise le contexte agricole ci-dessous pour enrichir ta réponse, mais ne le cite pas directement:\n$ragContext' : 'Si le contexte ne contient pas d\'informations pertinentes, utilise tes connaissances générales en agriculture.'}

Réponds de manière concise (2-3 phrases maximum) et pertinente au sujet des plantes et de l'agriculture.
Si la question ne concerne pas l'agriculture ou l'agronomie, dis poliment que tu es spécialisé dans ces domaines uniquement.

Message de l'utilisateur: "$userMessage"''';

      final response = await _model.generateContent([
        Content.text(systemPrompt),
      ]);

      return response.text ?? 'Désolé, je n\'ai pas pu traiter votre demande.';
    } catch (e) {
      return 'Une erreur s\'est produite: $e';
    }
  }

  /// Analyser une image de plante avec contexte RAG
  Future<String> analyzePlantImage(List<int> imageBytes) async {
    try {
      final systemPrompt = '''Analyse cette image de plante et identifie:
1. Le type de plante (si possible)
2. Toute maladie, anomalie ou problème visible
3. Les recommandations de traitement basées sur les meilleures pratiques agronomiques

Context: Tu es un expert en agronomie et détection de maladies des plantes. 
Réponds en français de manière précise et pratique.
Limite ta réponse à 5-7 phrases.''';

      final response = await _model.generateContent([
        Content.multi([
          TextPart(systemPrompt),
          DataPart('image/jpeg', Uint8List.fromList(imageBytes)),
        ]),
      ]);

      return response.text ?? 'Impossible d\'analyser l\'image.';
    } catch (e) {
      return 'Erreur lors de l\'analyse: $e';
    }
  }

  /// Obtenir des conseils sur les soins des plantes avec contexte RAG
  Future<String> getPlantCareAdvice(String plantName) async {
    try {
      // Récupérer le contexte RAG pour cette plante
      final ragContext = await _buildRagContext('conseils soins $plantName agronomie culture');

      final systemPrompt = '''Tu es Green Bot, expert en agronomie et culture des plantes.
Donne des conseils rapides et pratiques pour soigner une "$plantName".
Inclus: arrosage, lumière, température, fertilisation, prévention des maladies.

${ragContext.isNotEmpty ? 'Référence-toi au contexte agronomique suivant:\n$ragContext' : 'Utilise tes connaissances générales en agronomie.'}

Réponds en français de manière concise (5-7 phrases) et pratique pour un agriculteur ou un jardinier.''';

      final response = await _model.generateContent([
        Content.text(systemPrompt),
      ]);

      return response.text ?? 'Impossible d\'obtenir les conseils.';
    } catch (e) {
      return 'Erreur: $e';
    }
  }

  /// Identify disease from plant image with RAG agricultural context
  Future<String> identifyPlantDisease(List<int> imageBytes) async {
    try {
      final systemPrompt = '''Analyse cette image pour identifier la maladie ou le problème de la plante.
Fournis:
1. Nom de la maladie (en français et scientifique si possible)
2. Symptômes observés
3. Causatives (champignon, bactérie, virus, carence, insecte, etc.)
4. Traitements recommandés selon les meilleures pratiques agronomiques

Tu es un phytopathologiste expert en agronomie.
Réponds en français de manière structurée et professionnelle.''';

      final response = await _model.generateContent([
        Content.multi([
          TextPart(systemPrompt),
          DataPart('image/jpeg', Uint8List.fromList(imageBytes)),
        ]),
      ]);

      return response.text ?? 'Impossible d\'identifier la maladie.';
    } catch (e) {
      return 'Erreur lors de l\'identification: $e';
    }
  }
}

// Instance singleton
final geminiService = GeminiService();
