// Règle de décision classifier_v1 (2.2.0), commune avec le backend :
// culture choisie avant la photo, best = argmax sur les 9 classes,
// wrong_crop → unknown (< 0,70) → ok. Réécrit en 2.2.0 : l'ancienne règle
// (seuil + écart avec la 2e classe) est supprimée.

import 'package:flutter_test/flutter_test.dart';
import 'package:green_app/core/constants/app_constants.dart';
import 'package:green_app/models/scan_result_model.dart';
import 'package:green_app/services/vision/classification.dart';
import 'package:green_app/services/vision/decision_rule.dart';
import 'package:green_app/services/vision_service.dart';

import 'support/catalog.dart';

const _labels = [
  'Cassava Brown Leaf Spot', 'Cassava Healthy', 'Cassava Mosaic', //
  'Corn Healthy', 'Corn Yellowing', 'Corn leaf blight', //
  'Tomato Brown Spots', 'Tomato blight leaf', 'Tomato healthy',
];

/// Distribution sur les 9 classes : [main] reçoit [p], le reste est réparti
/// (ou donné explicitement par [others]).
ClassificationResult _probs(String main, double p, {Map<String, double> others = const {}}) {
  final rest = 1 - p - others.values.fold<double>(0, (a, b) => a + b);
  final free = _labels.where((l) => l != main && !others.containsKey(l)).length;
  return ClassificationResult.fromProbabilities(
    [for (final l in _labels) l == main ? p : (others[l] ?? rest / free)],
    _labels,
  );
}

void main() {
  final catalog = loadCatalog();
  ScanResultModel interpret(ClassificationResult r, String crop) => VisionService.interpret(
        r,
        catalog: catalog,
        chosenCropId: crop,
        id: 'x',
        imagePath: '/tmp/x.jpg',
        scannedAt: DateTime(2026, 11, 20),
        source: 'camera',
        modelVersion: 'classifier_v1',
      );

  group('DecisionRule', () {
    test('seuil unique : 0,70, en un seul endroit (AppConstants)', () {
      expect(AppConstants.visionConfidenceThreshold, 0.70);
    });

    test('noms de statut identiques au backend', () {
      expect(VisionDecision.values.map((d) => d.wire), ['ok', 'unknown', 'wrong_crop']);
      expect(VisionDecision.fromWire('wrong_crop'), VisionDecision.wrongCrop);
      expect(VisionDecision.fromWire('uncertain'), isNull);
    });

    test('culture = premier mot de la classe (Corn → maize)', () {
      expect(DecisionRule.cropOf('Corn leaf blight'), 'maize');
      expect(DecisionRule.cropOf('Cassava Mosaic'), 'cassava');
      expect(DecisionRule.cropOf('Tomato healthy'), 'tomato');
      expect(DecisionRule.cropOf('Banana Healthy'), isNull);
    });

    test('ok : bonne culture et confiance ≥ 0,70 (0,70 pile compris)', () {
      expect(DecisionRule.decide(_probs('Corn leaf blight', 0.941), chosenCrop: 'maize'), VisionDecision.ok);
      expect(DecisionRule.decide(_probs('Corn Healthy', 0.70), chosenCrop: 'maize'), VisionDecision.ok);
    });

    test('unknown : bonne culture mais confiance < 0,70', () {
      expect(DecisionRule.decide(_probs('Corn leaf blight', 0.58), chosenCrop: 'maize'), VisionDecision.unknown);
      expect(DecisionRule.decide(_probs('Corn leaf blight', 0.6999), chosenCrop: 'maize'), VisionDecision.unknown);
    });

    test('wrong_crop : la classe la plus probable est d\'une autre culture, même très sûre', () {
      expect(DecisionRule.decide(_probs('Cassava Mosaic', 0.974), chosenCrop: 'tomato'), VisionDecision.wrongCrop);
    });

    test('wrong_crop est testé avant le seuil', () {
      expect(DecisionRule.decide(_probs('Cassava Mosaic', 0.40), chosenCrop: 'tomato'), VisionDecision.wrongCrop);
    });

    test('jamais de renormalisation sur les 3 classes de la culture choisie', () {
      // Tomate choisie ; les 3 classes tomate valent 0,50 + 0,05 + 0,05.
      // Renormalisées sur la tomate, « Tomato blight leaf » ferait 0,83 (ok).
      // La règle garde 0,50 → unknown.
      final r = _probs('Tomato blight leaf', 0.50, others: {'Tomato Brown Spots': 0.05, 'Tomato healthy': 0.05});
      expect(DecisionRule.decide(r, chosenCrop: 'tomato'), VisionDecision.unknown);
    });

    test('jamais de maximum pris seulement sur la culture choisie', () {
      // Le manioc domine : le maximum parmi les classes tomate (0,30) ne doit
      // pas être retenu ; c'est wrong_crop.
      final r = _probs('Cassava Mosaic', 0.60, others: {'Tomato blight leaf': 0.30});
      expect(DecisionRule.decide(r, chosenCrop: 'tomato'), VisionDecision.wrongCrop);
    });
  });

  group('VisionService.interpret', () {
    test('ok, classe malade → maladie probable, fiche et culture rattachées', () {
      final s = interpret(_probs('Corn leaf blight', 0.91), 'maize');
      expect(s.decision, VisionDecision.ok);
      expect(s.status, ScanStatus.diseased);
      expect(s.diseaseId, 'maize-northern-leaf-blight');
      expect(s.cropId, 'maize');
      expect(s.chosenCropId, 'maize');
      expect(s.plantName, 'Maïs');
      expect(s.confidence, 0.91);
      expect(s.modelVersion, 'classifier_v1');
    });

    test('ok, classes du manioc : taches brunes et manioc sain', () {
      final spot = interpret(_probs('Cassava Brown Leaf Spot', 0.88), 'cassava');
      expect(spot.status, ScanStatus.diseased);
      expect(spot.diseaseId, 'cassava-brown-leaf-spot');
      final healthy = interpret(_probs('Cassava Healthy', 0.95), 'cassava');
      expect(healthy.status, ScanStatus.healthy);
      expect(healthy.diseaseId, 'cassava-healthy');
    });

    test('unknown → incertain, sans diagnostic, classe brute conservée', () {
      final s = interpret(_probs('Corn leaf blight', 0.58), 'maize');
      expect(s.decision, VisionDecision.unknown);
      expect(s.status, ScanStatus.uncertain);
      expect(s.diseaseId, isNull);
      expect(s.label, 'Corn leaf blight');
      expect(s.topPredictions, hasLength(3));
    });

    test('wrong_crop → statut « autre culture », culture affichée = culture choisie', () {
      final s = interpret(_probs('Cassava Mosaic', 0.974), 'tomato');
      expect(s.decision, VisionDecision.wrongCrop);
      expect(s.status, ScanStatus.wrongCrop);
      expect(s.isWrongCrop, isTrue);
      expect(s.diseaseId, isNull);
      expect(s.cropId, 'tomato');
      expect(s.label, 'Cassava Mosaic');
    });

    test('une plante saine reconnue à 99 % n\'est pas présentée comme « gravité très élevée »', () {
      final healthy = interpret(_probs('Corn Healthy', 0.99), 'maize');
      expect(healthy.isHealthy, isTrue);
      expect(catalog.findById('maize-healthy')!.severity.name, 'none');
    });
  });

  test('historique : décision et culture choisie enregistrées, anciennes analyses lisibles', () {
    final s = interpret(_probs('Cassava Mosaic', 0.974), 'tomato');
    final back = ScanResultModel.fromJson(s.toJson());
    expect(back.decision, VisionDecision.wrongCrop);
    expect(back.status, ScanStatus.wrongCrop);
    expect(back.chosenCropId, 'tomato');
    expect(s.toJson()['decision'], 'wrong_crop');

    final old = s.toJson()
      ..remove('decision')
      ..remove('chosen_crop')
      ..['status'] = 'uncertain';
    final legacy = ScanResultModel.fromJson(old);
    expect(legacy.decision, isNull);
    expect(legacy.chosenCropId, isNull);
    expect(legacy.status, ScanStatus.uncertain);
  });
}
