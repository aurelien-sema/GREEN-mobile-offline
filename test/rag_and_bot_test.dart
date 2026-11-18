import 'package:flutter_test/flutter_test.dart';
import 'package:green_app/services/gemini/gemini_service.dart';
import 'package:green_app/services/rag_service.dart';
import 'package:green_app/services/voice/voice_recorder_service.dart';

void main() {
  test('BM25 classe l\'extrait pertinent en premier, insensible aux accents', () {
    final texts = [
      'Le manioc se plante en début de saison des pluies avec des boutures saines.',
      'La chenille légionnaire d\'automne attaque le cornet du maïs.',
      'Le cacao demande de l\'ombrage.',
    ];
    expect(RagService.searchTexts(texts, 'chenille legionnaire mais').first, 1);
    expect(RagService.searchTexts(texts, 'boutures manioc').first, 0);
    expect(RagService.searchTexts(texts, 'xyz'), isEmpty);
  });

  test('le Markdown des réponses est retiré', () {
    expect(GeminiService.stripMarkdownForTest('**Attention** :\n- arrosez\n# Titre'), 'Attention :\narrosez\nTitre');
  });

  test('niveau sonore : dBFS normalisés entre 0 et 1', () {
    expect(VoiceRecorderService.normalizeDb(-160), 0);
    expect(VoiceRecorderService.normalizeDb(0), 1);
    final mid = VoiceRecorderService.normalizeDb(-25);
    expect(mid, inExclusiveRange(0, 1));
    expect(VoiceRecorderService.normalizeDb(double.nan), 0);
  });
}
