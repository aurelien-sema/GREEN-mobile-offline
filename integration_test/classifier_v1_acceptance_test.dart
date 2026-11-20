// Test d'acceptation de classifier_v1 (GREEN mobile 2.2.0) avec le VRAI
// modèle : prétraitement réel de l'app (ImagePreprocessor, dans un
// isolate), interpréteur TFLite réel (TfliteVisionModel) et règle de
// décision complète (DecisionRule + VisionService.interpret), sur les 12
// cas du tableau fourni avec le modèle (test/support/classifier_v1_cases.dart).
//
// Il tourne sur un téléphone ou un émulateur Android (le moteur TFLite n'est
// pas disponible pour `flutter test` sur PC) :
//
//     flutter test integration_test/classifier_v1_acceptance_test.dart -d <appareil>
//
// À relancer si un délégué GPU ou NNAPI est activé.
// Images : integration_test/classifier_v1_fixtures.g.dart, généré par
// tools/vision/make_classifier_v1_fixtures.py.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:green_app/core/constants/app_constants.dart';
import 'package:green_app/providers/diseases_provider.dart';
import 'package:green_app/services/vision/decision_rule.dart';
import 'package:green_app/services/vision/vision_model.dart';
import 'package:green_app/services/vision_service.dart';
import 'package:integration_test/integration_test.dart';

import '../test/support/classifier_v1_cases.dart';
import 'classifier_v1_fixtures.g.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final engine = VisionEngine();
  final catalog = DiseasesProvider();

  setUpAll(() async {
    await catalog.load();
    expect(await engine.activeModelId(), 'classifier_v1');
    expect(AppConstants.visionConfidenceThreshold, 0.70);
  });

  for (final c in classifierV1Cases) {
    testWidgets('${c.fixture} (culture choisie : ${c.chosenCrop}) → ${c.status} ${c.label} ${c.confidence}',
        (tester) async {
      final bytes = base64Decode(classifierV1Fixtures[c.fixture]!);
      final result = await tester.runAsync(() => engine.classify(bytes));

      final decision = DecisionRule.decide(result!, chosenCrop: c.chosenCrop);
      final scan = VisionService.interpret(
        result,
        catalog: catalog,
        chosenCropId: c.chosenCrop,
        id: c.fixture,
        imagePath: '',
        scannedAt: DateTime(2026),
        source: 'gallery',
        modelVersion: 'classifier_v1',
      );
      // ignore: avoid_print
      print('${c.fixture} [${c.chosenCrop}] : ${decision.wire} ${result.label} '
          '${result.confidence.toStringAsFixed(3)} (attendu ${c.status} ${c.label} ${c.confidence}) '
          'inférence ${result.inferenceTime?.inMilliseconds} ms');

      expect(result.label, c.label, reason: 'classe la plus probable parmi les 9');
      expect(decision.wire, c.status);
      expect(scan.decision?.wire, c.status);
      expect(result.confidence, closeTo(c.confidence, confidenceTolerance),
          reason: 'écart > ±$confidenceTolerance : prétraitement différent de l\'entraînement ?');
      expect(result.probabilities.fold<double>(0, (a, b) => a + b), closeTo(1, 1e-3),
          reason: 'sortie déjà en probabilités, sans softmax ni renormalisation');
    });
  }
}
