import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:green_app/services/vision/classification.dart';
import 'package:green_app/services/vision/image_preprocessor.dart';
import 'package:green_app/services/vision/model_spec.dart';
import 'package:green_app/services/vision/vision_model.dart';
import 'package:image/image.dart' as img;

ModelSpec _spec(String path) => ModelSpec.parse(File(path).readAsStringSync());

void main() {
  final tflite = _spec('assets/models/active_model.json');
  final onnx = _spec('assets/models/onnx/onnx_model.json');

  group('Configuration des modèles', () {
    test('le modèle actif de la v2.1 est le TFLite 9 classes', () {
      expect(tflite.format, ModelFormat.tflite);
      expect(tflite.modelAsset, 'assets/models/tflite/plant_classifier_float16.tflite');
      expect(tflite.inputShape, [1, 224, 224, 3]);
      expect(tflite.pixels, PixelScaling.raw0255);
      expect(tflite.resize, ResizeMode.stretchBilinear);
      expect(tflite.output, OutputKind.probabilities);
    });

    test('la configuration correspond à la fiche technique fournie avec le modèle', () {
      final official = jsonDecode(File('assets/models/tflite/model_spec.json').readAsStringSync()) as Map<String, dynamic>;
      expect(tflite.inputShape, official['input_shape']);
      expect(tflite.modelAsset.split('/').last, official['file']);
      final labels = ModelSpec.parseLabels(File(tflite.labelsAsset).readAsStringSync());
      expect(labels, official['classes'], reason: 'labels.txt doit suivre l\'ordre des sorties');
      expect(labels, hasLength(9));
      expect(File(tflite.modelAsset).existsSync(), isTrue, reason: 'fichier .tflite présent');
    });

    test('le pubspec embarque le modèle actif, pas le modèle ONNX', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      expect(pubspec, contains('- assets/models/tflite/'));
      expect(pubspec, contains('- assets/models/active_model.json'));
      expect(pubspec, isNot(contains('- assets/models/onnx/')));
      expect(pubspec, contains('tflite_flutter:'));
      expect(pubspec, contains('flutter_onnxruntime:'));
    });

    test('le modèle ONNX reste branchable (configuration valide)', () {
      expect(onnx.format, ModelFormat.onnx);
      expect(onnx.inputShape, [1, 3, 224, 224]);
      expect(onnx.resize, ResizeMode.shorterSideCenterCrop);
      expect(onnx.shorterSide, 255);
      expect(onnx.output, OutputKind.logits);
      expect(ModelSpec.parseLabels(File(onnx.labelsAsset).readAsStringSync()), hasLength(11));
    });

    test('une configuration incomplète est refusée avec un message clair', () {
      expect(() => ModelSpec.parse('{"format":"tflite","model":"m","labels":"l","input":{"width":0,"height":224,"pixels":"raw_0_255"}}'),
          throwsFormatException);
      expect(() => ModelSpec.parse('{"format":"pt","model":"m","labels":"l","input":{"width":224,"height":224,"pixels":"raw_0_255"}}'),
          throwsFormatException);
      expect(() => ModelSpec.parse('{"format":"onnx","model":"m","labels":"l","input":{"width":224,"height":224,"pixels":"imagenet","resize":"shorter_side_center_crop","shorterSide":100}}'),
          throwsFormatException);
    });

    test('labels.txt : virgules finales et lignes vides ignorées', () {
      expect(ModelSpec.parseLabels('Corn Healthy,\n\nTomato healthy\n'), ['Corn Healthy', 'Tomato healthy']);
    });

    test('le moteur choisit l\'implémentation d\'après le format', () {
      expect(VisionModel.fromSpec(tflite).runtimeType.toString(), 'TfliteVisionModel');
      expect(VisionModel.fromSpec(onnx).runtimeType.toString(), 'OnnxVisionModel');
    });
  });

  group('Prétraitement TFLite (NHWC, pixels bruts 0–255)', () {
    test('canaux dans l\'ordre R, G, B, valeurs non normalisées', () {
      final red = img.Image(width: 224, height: 224)..clear(img.ColorRgb8(255, 10, 0));
      final t = ImagePreprocessor.toTensor(red, tflite);
      expect(t.length, 224 * 224 * 3);
      expect(t.sublist(0, 3), [255.0, 10.0, 0.0]);
      expect(t.sublist(t.length - 3), [255.0, 10.0, 0.0]);
    });

    test('photo 4000×3000 → 224×224 (proportions non conservées, comme à l\'entraînement)', () {
      final out = ImagePreprocessor.resizeStretch(img.Image(width: 4000, height: 3000), 224, 224);
      expect((out.width, out.height), (224, 224));
    });

    test('redimensionnement fidèle au bilinéaire de référence (OpenCV / TensorFlow)', () {
      final bytes = File('test/fixtures/leaf_synthetic_640x480.png').readAsBytesSync();
      final reference = File('test/fixtures/leaf_synthetic_224_bilinear.rgb').readAsBytesSync();
      final t = ImagePreprocessor.preprocess(bytes, tflite)!;
      expect(t.length, reference.length);
      var sum = 0.0;
      for (var i = 0; i < t.length; i++) {
        sum += (t[i] - reference[i]).abs();
      }
      final mae = sum / t.length;
      // Écart moyen par pixel, sur 255. Le jeu de contrôle ne montre aucune
      // perte de précision jusqu'à ~3 (PIL avec anti-crénelage vs OpenCV).
      expect(mae, lessThan(3.0), reason: 'MAE = ${mae.toStringAsFixed(2)}');
      // ignore: avoid_print
      print('MAE prétraitement Dart vs référence : ${mae.toStringAsFixed(3)}');
    });

    test('photo en orientation EXIF portrait, PNG transparent, 16 bits : acceptées', () {
      final rgba = img.Image(width: 400, height: 300, numChannels: 4)..clear(img.ColorRgba8(0, 128, 0, 255));
      expect(ImagePreprocessor.preprocess(img.encodePng(rgba), tflite)!.length, 3 * 224 * 224);
      final deep = img.Image(width: 300, height: 300, format: img.Format.uint16);
      expect(ImagePreprocessor.preprocess(img.encodePng(deep), tflite)!.length, 3 * 224 * 224);
      final portrait = img.Image(width: 300, height: 200)..exif.imageIfd['Orientation'] = 6;
      expect(ImagePreprocessor.decodeRgb(img.encodeJpg(portrait))!.width, 200);
    });

    test('fichier illisible → null (et non une exception)', () {
      expect(ImagePreprocessor.preprocess(Uint8List.fromList([1, 2, 3]), tflite), isNull);
    });
  });

  group('Prétraitement ONNX (NCHW, ImageNet)', () {
    test('Resize(255) puis CenterCrop(224), comme torchvision', () {
      final out = ImagePreprocessor.resizeAndCenterCrop(img.Image(width: 4000, height: 3000), 255, 224, 224);
      expect((out.width, out.height), (224, 224));
      expect(ImagePreprocessor.resizeAndCenterCrop(img.Image(width: 300, height: 1200), 255, 224, 224).width, 224);
    });

    test('plans séparés et normalisation ImageNet', () {
      final white = img.Image(width: 224, height: 224)..clear(img.ColorRgb8(255, 255, 255));
      final data = ImagePreprocessor.toTensor(white, onnx);
      const plane = 224 * 224;
      expect(data[0], closeTo((1 - 0.485) / 0.229, 1e-5));
      expect(data[plane], closeTo((1 - 0.456) / 0.224, 1e-5));
      expect(data[2 * plane], closeTo((1 - 0.406) / 0.225, 1e-5));
    });
  });

  group('Sorties du modèle', () {
    test('probabilités : top 3 trié, renormalisées (float16 ≈ 0,9999)', () {
      final r = ClassificationResult.fromScores([0.1, 0.6, 0.29, 0.0099], ['a', 'b', 'c', 'd'], kind: OutputKind.probabilities);
      expect(r.label, 'b');
      expect(r.top.map((p) => p.label), ['b', 'c', 'a']);
      expect(r.top.fold<double>(0, (s, p) => s + p.confidence), lessThanOrEqualTo(1.0));
      expect(r.margin, closeTo(0.31, 0.01));
    });

    test('logits : softmax stable avec de grandes valeurs', () {
      final p = ClassificationResult.softmax([1000, 1001, 1002]);
      expect(p.reduce((a, b) => a + b), closeTo(1, 1e-9));
      final r = ClassificationResult.fromScores([0.1, 3.0, 2.9, -1.0], ['a', 'b', 'c', 'd'], kind: OutputKind.logits);
      expect(r.label, 'b');
      expect(r.margin, lessThan(0.1));
    });

    test('valeurs négatives ou NaN ignorées', () {
      final r = ClassificationResult.fromScores([double.nan, -0.2, 0.5], ['a', 'b', 'c'], kind: OutputKind.probabilities);
      expect(r.label, 'c');
      expect(r.confidence, 1.0);
    });

    test('nombre de sorties ≠ nombre de classes → erreur explicite', () {
      expect(() => ClassificationResult.fromScores([0.5, 0.5], ['a'], kind: OutputKind.probabilities), throwsStateError);
    });
  });

  test('VisionEngine : configuration lue une fois, modèle injectable', () async {
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
    expect(await engine.activeModelId(), 'plant-classifier-9c-fp16');
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
    return ClassificationResult.fromScores(scores, labels, kind: OutputKind.probabilities);
  }

  @override
  Future<void> dispose() async {}
}
