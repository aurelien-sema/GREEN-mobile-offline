// Pipeline de vision classifier_v1 (2.2.0), sans le moteur TFLite :
// configuration, prétraitement (RGB, bilinéaire anti-crénelé, 0–255, NHWC)
// et sortie brute. Le vrai modèle est testé sur téléphone par
// integration_test/classifier_v1_acceptance_test.dart.
//
// Réécrit en 2.2.0 : les tests de l'ancien modèle ONNX (NCHW, ImageNet,
// recadrage central, logits/softmax) sont supprimés avec ce modèle.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:green_app/services/vision/classification.dart';
import 'package:green_app/services/vision/decision_rule.dart';
import 'package:green_app/services/vision/image_preprocessor.dart';
import 'package:green_app/services/vision/model_spec.dart';
import 'package:green_app/services/vision/vision_model.dart';
import 'package:image/image.dart' as img;

import 'support/classifier_v1_cases.dart';

void main() {
  final spec = ModelSpec.parse(File('assets/models/active_model.json').readAsStringSync());
  final labels = ModelSpec.parseLabels(File(spec.labelsAsset).readAsStringSync());

  group('Configuration de classifier_v1', () {
    test('modèle actif : classifier_v1, TFLite, entrée [1, 224, 224, 3]', () {
      expect(spec.id, 'classifier_v1');
      expect(spec.modelAsset, 'assets/models/tflite/plant_classifier_float16.tflite');
      expect(spec.inputShape, [1, 224, 224, 3]);
    });

    test('conforme à la fiche technique fournie avec le modèle (model_spec.json)', () {
      final official = jsonDecode(File('assets/models/tflite/model_spec.json').readAsStringSync()) as Map<String, dynamic>;
      expect(spec.inputShape, official['input_shape']);
      expect(spec.modelAsset.split('/').last, official['file']);
      expect(labels, official['classes'], reason: 'labels.txt doit suivre l\'ordre des sorties');
      expect(labels, [
        'Cassava Brown Leaf Spot', 'Cassava Healthy', 'Cassava Mosaic', //
        'Corn Healthy', 'Corn Yellowing', 'Corn leaf blight', //
        'Tomato Brown Spots', 'Tomato blight leaf', 'Tomato healthy',
      ]);
      expect(File(spec.modelAsset).lengthSync(), 8100516, reason: 'plant_classifier_float16.tflite (8,1 Mo)');
    });

    test('pubspec : seul le modèle TFLite est embarqué ; ancien modèle ONNX supprimé', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      expect(pubspec, contains('- assets/models/tflite/'));
      expect(pubspec, contains('- assets/models/active_model.json'));
      expect(pubspec, isNot(contains('- assets/models/onnx/')));
      expect(Directory('assets/models/onnx').existsSync(), isFalse);
      expect(File('lib/services/vision/onnx_vision_model.dart').existsSync(), isFalse);
    });

    test('Android : le .tflite n\'est pas compressé dans l\'APK', () {
      expect(File('android/app/build.gradle.kts').readAsStringSync(), contains('noCompress += "tflite"'));
    });

    test('une configuration de l\'ancien modèle ou incomplète est refusée', () {
      const base = '"model":"m","labels":"l"';
      expect(() => ModelSpec.parse('{"format":"onnx",$base,"input":{"width":224,"height":224}}'), throwsFormatException);
      expect(() => ModelSpec.parse('{"format":"tflite",$base,"input":{"width":224,"height":224,"pixels":"imagenet"}}'),
          throwsFormatException);
      expect(() => ModelSpec.parse('{"format":"tflite",$base,"input":{"width":224,"height":224,"layout":"nchw"}}'),
          throwsFormatException);
      expect(() => ModelSpec.parse('{"format":"tflite",$base,"input":{"width":224,"height":224},"output":{"kind":"logits"}}'),
          throwsFormatException);
      expect(() => ModelSpec.parse('{"format":"tflite",$base,"input":{"width":0,"height":224}}'), throwsFormatException);
    });

    test('labels.txt : virgules finales et lignes vides ignorées', () {
      expect(ModelSpec.parseLabels('Corn Healthy,\n\nTomato healthy\n'), ['Corn Healthy', 'Tomato healthy']);
    });

    test('chaque classe commence par une culture : Cassava, Corn ou Tomato', () {
      expect(labels.map(DecisionRule.cropOf).toSet(), {'cassava', 'maize', 'tomato'});
    });

    test('implémentation de l\'app : TFLite', () {
      expect(VisionModel.fromSpec(spec).runtimeType.toString(), 'TfliteVisionModel');
    });
  });

  group('Prétraitement (comme à l\'entraînement)', () {
    test('pixels RGB dans cet ordre, valeurs brutes 0–255 (ni /255, ni moyenne), NHWC', () {
      final red = img.Image(width: 300, height: 200)..clear(img.ColorRgb8(255, 10, 0));
      final t = ImagePreprocessor.preprocess(img.encodePng(red), spec)!;
      expect(t.length, 224 * 224 * 3);
      for (final i in [0, 3 * 224 * 112 + 3 * 57, t.length - 3]) {
        expect(t[i], closeTo(255, 1e-3));
        expect(t[i + 1], closeTo(10, 1e-3));
        expect(t[i + 2], closeTo(0, 1e-3));
      }
    });

    test('image étirée à 224×224 sans recadrage : les bords restent visibles', () {
      // Bande bleue de 10 % à gauche d'une image large : un recadrage central
      // la ferait disparaître, l'étirement la garde (~22 colonnes).
      final wide = img.Image(width: 800, height: 400)..clear(img.ColorRgb8(0, 200, 0));
      img.fillRect(wide, x1: 0, y1: 0, x2: 79, y2: 399, color: img.ColorRgb8(0, 0, 255));
      final t = ImagePreprocessor.preprocess(img.encodePng(wide), spec)!;
      double blueAt(int x) => t[(112 * 224 + x) * 3 + 2];
      expect(blueAt(0), closeTo(255, 1e-3));
      expect(blueAt(20), greaterThan(200));
      expect(blueAt(30), lessThan(1));
    });

    test('anti-crénelage : un damier fin (1 px) donne un gris uniforme, sans moiré', () {
      const n = 2240; // 10× la taille d'entrée, comme une photo de téléphone
      final rgb = Uint8List(n * n * 3);
      for (var y = 0; y < n; y++) {
        for (var x = 0; x < n; x++) {
          final v = (x + y).isEven ? 255 : 0;
          final p = (y * n + x) * 3;
          rgb[p] = v;
          rgb[p + 1] = v;
          rgb[p + 2] = v;
        }
      }
      final t = ImagePreprocessor.resizeAntialiased(rgb, n, n, 224, 224);
      var lo = 255.0, hi = 0.0;
      for (final v in t) {
        if (v < lo) lo = v;
        if (v > hi) hi = v;
      }
      // Un bilinéaire simple (4 voisins) donnerait des valeurs proches de 0
      // ou de 255 selon la phase : du moiré que l'entraînement n'a jamais vu.
      expect(lo, greaterThan(120));
      expect(hi, lessThan(135));
    });

    test('identique à Pillow BILINEAR (anti-crénelé, comme tf.image.resize(antialias=True))', () {
      final bytes = File('test/fixtures/leaf_synthetic_640x480.png').readAsBytesSync();
      final reference = File('test/fixtures/leaf_synthetic_224_pil_bilinear.rgb').readAsBytesSync();
      final t = ImagePreprocessor.preprocess(bytes, spec)!;
      expect(t.length, reference.length);
      var sum = 0.0, worst = 0.0;
      for (var i = 0; i < t.length; i++) {
        final d = (t[i] - reference[i]).abs();
        sum += d;
        if (d > worst) worst = d;
      }
      final mae = sum / t.length;
      // Pillow arrondit à l'entier entre ses deux passages : ±1 au plus.
      expect(mae, lessThan(0.6), reason: 'MAE = ${mae.toStringAsFixed(3)}');
      expect(worst, lessThan(2.0), reason: 'écart max = ${worst.toStringAsFixed(2)}');
    });

    test('feuilles du test d\'acceptation : décodage et prétraitement OK', () {
      for (final c in classifierV1Cases) {
        final bytes = File('test/fixtures/classifier_v1/${c.fixture}').readAsBytesSync();
        final t = ImagePreprocessor.preprocess(bytes, spec);
        expect(t, isNotNull, reason: c.fixture);
        expect(t!.length, 224 * 224 * 3);
        // Poids positifs et normalisés : 0–255 à l'arrondi flottant près.
        expect(t.every((v) => v >= -1e-3 && v <= 255 + 1e-3), isTrue, reason: '${c.fixture} : valeurs hors 0–255');
      }
    });

    test('PNG transparent (alpha retiré), 16 bits, EXIF portrait : acceptés', () {
      final rgba = img.Image(width: 400, height: 300, numChannels: 4)..clear(img.ColorRgba8(0, 128, 0, 100));
      final t = ImagePreprocessor.preprocess(img.encodePng(rgba), spec)!;
      expect(t.length, 3 * 224 * 224);
      expect(t[1], closeTo(128, 1e-3), reason: 'alpha ignoré, pas de composition');
      final deep = img.Image(width: 300, height: 300, format: img.Format.uint16);
      expect(ImagePreprocessor.preprocess(img.encodePng(deep), spec)!.length, 3 * 224 * 224);
      final portrait = img.Image(width: 300, height: 200)..exif.imageIfd['Orientation'] = 6;
      expect(ImagePreprocessor.decodeRgb(img.encodeJpg(portrait))!.width, 200);
    });

    test('petite image : agrandie en bilinéaire', () {
      final small = img.Image(width: 100, height: 100)..clear(img.ColorRgb8(10, 20, 30));
      final t = ImagePreprocessor.preprocess(img.encodePng(small), spec)!;
      expect(t.sublist(0, 3).map((v) => v.round()), [10, 20, 30]);
    });

    test('fichier illisible → null (et non une exception)', () {
      expect(ImagePreprocessor.preprocess(Uint8List.fromList([1, 2, 3]), spec), isNull);
    });
  });

  group('Sortie du modèle', () {
    test('probabilités gardées telles quelles : ni softmax, ni renormalisation', () {
      final r = ClassificationResult.fromProbabilities([0.1, 0.6, 0.29, 0.0099], ['a', 'b', 'c', 'd']);
      expect(r.label, 'b');
      expect(r.confidence, 0.6);
      expect(r.probabilities, [0.1, 0.6, 0.29, 0.0099]);
      expect(r.top.map((p) => p.label), ['b', 'c', 'a']);
    });

    test('sortie invalide (NaN, négative, mauvaise taille) refusée', () {
      expect(() => ClassificationResult.fromProbabilities([double.nan, 0.5, 0.5], ['a', 'b', 'c']), throwsStateError);
      expect(() => ClassificationResult.fromProbabilities([-0.1, 0.6, 0.5], ['a', 'b', 'c']), throwsStateError);
      expect(() => ClassificationResult.fromProbabilities([0.5, 0.5], ['a']), throwsStateError);
    });
  });

  test('VisionEngine : configuration lue une fois, modèle injectable, id classifier_v1', () async {
    var reads = 0;
    final engine = VisionEngine(
      readConfig: () async {
        reads++;
        return File('assets/models/active_model.json').readAsStringSync();
      },
      modelFactory: (spec) => _FakeModel(spec),
    );
    final r = await engine.classify(Uint8List(0));
    expect(r.label, 'Cassava Mosaic');
    await engine.classify(Uint8List(0));
    expect(reads, 1);
    expect(await engine.activeModelId(), 'classifier_v1');
  });
}

class _FakeModel implements VisionModel {
  @override
  final ModelSpec spec;
  _FakeModel(this.spec);

  @override
  List<String> get labels => ModelSpec.parseLabels(File(spec.labelsAsset).readAsStringSync());

  @override
  Future<void> load() async {}

  @override
  Future<ClassificationResult> classify(Uint8List imageBytes) async {
    final scores = List<double>.filled(labels.length, 0.01);
    scores[2] = 0.92;
    return ClassificationResult.fromProbabilities(scores, labels);
  }

  @override
  Future<void> dispose() async {}
}
