import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'classification.dart';
import 'image_preprocessor.dart';
import 'model_spec.dart';
import 'onnx_vision_model.dart';
import 'tflite_vision_model.dart';

/// Classifieur d'images hors ligne, quel que soit son format.
abstract class VisionModel {
  ModelSpec get spec;
  List<String> get labels;

  Future<void> load();

  /// Analyse une photo (octets JPEG/PNG/WebP…).
  Future<ClassificationResult> classify(Uint8List imageBytes);

  Future<void> dispose();

  /// Choisit l'implémentation d'après le format déclaré.
  static VisionModel fromSpec(ModelSpec spec) => switch (spec.format) {
        ModelFormat.tflite => TfliteVisionModel(spec),
        ModelFormat.onnx => OnnxVisionModel(spec),
      };

  /// Prétraitement dans un isolate : l'interface ne se fige pas pendant le
  /// décodage d'une photo de 12 Mpx.
  static Future<Float32List> prepare(Uint8List bytes, ModelSpec spec) async {
    final input = await Isolate.run(() => ImagePreprocessor.preprocess(bytes, spec));
    if (input == null) {
      throw const FormatException('Image illisible ou format non pris en charge.');
    }
    return input;
  }

  static Future<List<String>> loadLabels(ModelSpec spec) async {
    final labels = ModelSpec.parseLabels(await rootBundle.loadString(spec.labelsAsset));
    if (labels.isEmpty) throw StateError('${spec.labelsAsset} est vide.');
    return labels;
  }
}

/// Modèle actif de l'application, décrit par assets/models/active_model.json.
class VisionEngine {
  static const configAsset = 'assets/models/active_model.json';

  final Future<String> Function() _readConfig;
  /// Fabrique de modèle (injectée dans les tests ; null = selon le format).
  final VisionModel Function(ModelSpec)? modelFactory;
  Future<VisionModel>? _model;

  VisionEngine({Future<String> Function()? readConfig, this.modelFactory})
      : _readConfig = readConfig ?? (() => rootBundle.loadString(configAsset));

  /// Modèle chargé et prêt (chargement unique, réessayé après un échec).
  Future<VisionModel> model() => _model ??= _open().catchError((Object e) {
        _model = null;
        throw e;
      });

  Future<VisionModel> _open() async {
    final spec = ModelSpec.parse(await _readConfig());
    final model = (modelFactory ?? VisionModel.fromSpec)(spec);
    await model.load();
    debugPrint('Modèle de vision prêt : ${spec.id} (${spec.format.name}, ${model.labels.length} classes)');
    return model;
  }

  /// Classes du modèle actif sans charger le modèle lui-même (pour la base
  /// de maladies : « détectable par scan »).
  Future<List<String>> activeLabels() async {
    final spec = ModelSpec.parse(await _readConfig());
    return VisionModel.loadLabels(spec);
  }

  Future<ClassificationResult> classify(Uint8List bytes) async => (await model()).classify(bytes);

  Future<String> activeModelId() async {
    try {
      return ModelSpec.parse(await _readConfig()).id;
    } catch (_) {
      return 'unknown';
    }
  }
}

final visionEngine = VisionEngine();
