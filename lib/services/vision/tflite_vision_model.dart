import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:tflite_flutter/tflite_flutter.dart';

import 'classification.dart';
import 'decision_rule.dart';
import 'model_spec.dart';
import 'vision_model.dart';

/// Moteur TensorFlow Lite (LiteRT) — classifier_v1 :
/// plant_classifier_float16.tflite, 9 classes, entrée [1, 224, 224, 3]
/// float32 en pixels bruts 0–255, sortie [1, 9] en probabilités.
///
/// - Interpréteur créé **une seule fois** (au premier scan), puis réutilisé.
/// - Le modèle est lu depuis les assets en mémoire (fromBuffer). Il est
///   stocké non compressé dans l'APK (noCompress "tflite", 2.2.0) ;
///   tflite_flutter n'expose pas le mappage mémoire d'un asset Android, la
///   lecture reste donc une copie unique de ~8 Mo au chargement.
/// - L'inférence tourne **hors du fil de l'interface**, dans un isolate
///   dédié (IsolateInterpreter), seul à exécuter l'interpréteur ; les appels
///   sont mis en file (jamais deux inférences simultanées sur le même
///   interpréteur). Modifié en 2.2.0 : si cet isolate ne peut pas être
///   créé, le chargement échoue au lieu de basculer sur le fil principal.
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
    if (!listEquals(output.shape, [1, _labels.length])) {
      interpreter.close();
      throw StateError('Sortie du modèle ${output.shape}, ${spec.labelsAsset} liste ${_labels.length} classes '
          '(attendu [1, ${_labels.length}]).');
    }
    // Chaque classe doit commencer par une culture connue (règle wrong_crop).
    final orphans = _labels.where((l) => DecisionRule.cropOf(l) == null).toList();
    if (orphans.isNotEmpty) {
      interpreter.close();
      throw StateError('Classes sans culture reconnue (Cassava, Corn, Tomato) : $orphans');
    }
    try {
      _isolate = await IsolateInterpreter.create(address: interpreter.address);
    } catch (e) {
      interpreter.close();
      throw StateError('Impossible de lancer l\'inférence hors du fil principal : $e');
    }
    _interpreter = interpreter;
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
    final isolate = _isolate;
    if (isolate == null || _interpreter == null) throw StateError('Modèle TFLite fermé.');
    final out = Float32List(_labels.length);
    final watch = Stopwatch()..start();
    final inBytes = input.buffer.asUint8List();
    final outBytes = out.buffer.asUint8List();
    await isolate.run(inBytes, outBytes);
    watch.stop();
    // Probabilités utilisées telles quelles (pas de softmax ni de
    // renormalisation).
    return ClassificationResult.fromProbabilities(out.toList(), _labels, inferenceTime: watch.elapsed);
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
