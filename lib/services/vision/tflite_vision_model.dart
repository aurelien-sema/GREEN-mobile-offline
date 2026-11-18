import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:tflite_flutter/tflite_flutter.dart';

import 'classification.dart';
import 'model_spec.dart';
import 'vision_model.dart';

/// Moteur TensorFlow Lite (LiteRT) — modèle actif de la v2.1 :
/// plant_classifier_float16.tflite, 9 classes, entrée [1, 224, 224, 3]
/// float32 en pixels bruts 0–255, sortie en probabilités.
///
/// - Le modèle est chargé depuis les assets en mémoire (fromBuffer), sans
///   copie sur le disque.
/// - L'inférence tourne dans un isolate dédié (IsolateInterpreter) ; les
///   appels sont mis en file car cet isolate ignore un appel reçu pendant
///   qu'il en traite un autre.
/// - Formes et types des tenseurs vérifiés au chargement : un modèle qui ne
///   correspond pas à active_model.json est refusé avec un message clair au
///   lieu de donner des prédictions fausses.
class TfliteVisionModel implements VisionModel {
  @override
  final ModelSpec spec;

  Interpreter? _interpreter;
  IsolateInterpreter? _isolate;
  List<String> _labels = const [];
  Future<void>? _loading;
  Future<void> _queue = Future.value();

  TfliteVisionModel(this.spec);

  @override
  List<String> get labels => _labels;

  @override
  Future<void> load() => _loading ??= _load().catchError((Object e) {
        _loading = null;
        throw e;
      });

  Future<void> _load() async {
    _labels = await VisionModel.loadLabels(spec);
    final data = await rootBundle.load(spec.modelAsset);
    final options = InterpreterOptions()..threads = spec.threads;
    final interpreter = Interpreter.fromBuffer(data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes), options: options);

    final input = interpreter.getInputTensor(0);
    final output = interpreter.getOutputTensor(0);
    if (!listEquals(input.shape, spec.inputShape)) {
      interpreter.close();
      throw StateError('Entrée du modèle ${input.shape}, active_model.json annonce ${spec.inputShape}.');
    }
    if (input.type != TensorType.float32 || output.type != TensorType.float32) {
      interpreter.close();
      throw StateError('Seuls les modèles à entrée et sortie float32 sont pris en charge '
          '(entrée ${input.type}, sortie ${output.type}).');
    }
    final classes = output.shape.isEmpty ? 0 : output.shape.last;
    if (classes != _labels.length) {
      interpreter.close();
      throw StateError('Le modèle a $classes sorties, ${spec.labelsAsset} liste ${_labels.length} classes.');
    }
    _interpreter = interpreter;
    try {
      _isolate = await IsolateInterpreter.create(address: interpreter.address);
    } catch (e) {
      debugPrint('Isolate TFLite indisponible, inférence sur le fil principal : $e');
    }
  }

  @override
  Future<ClassificationResult> classify(Uint8List imageBytes) async {
    await load();
    final input = await VisionModel.prepare(imageBytes, spec);
    final run = _queue.then((_) => _infer(input));
    _queue = run.then((_) {}, onError: (_) {});
    return run;
  }

  Future<ClassificationResult> _infer(Float32List input) async {
    final interpreter = _interpreter;
    if (interpreter == null) throw StateError('Modèle TFLite fermé.');
    final out = Float32List(_labels.length);
    final watch = Stopwatch()..start();
    final inBytes = input.buffer.asUint8List();
    final outBytes = out.buffer.asUint8List();
    final isolate = _isolate;
    if (isolate != null) {
      await isolate.run(inBytes, outBytes);
    } else {
      interpreter.run(inBytes, outBytes);
    }
    watch.stop();
    return ClassificationResult.fromScores(
      out.toList(),
      _labels,
      kind: spec.output,
      inferenceTime: watch.elapsed,
    );
  }

  @override
  Future<void> dispose() async {
    await _queue;
    await _isolate?.close();
    _interpreter?.close();
    _isolate = null;
    _interpreter = null;
    _loading = null;
  }
}
