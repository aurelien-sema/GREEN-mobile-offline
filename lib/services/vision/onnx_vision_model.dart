import 'dart:typed_data';

import 'package:flutter_onnxruntime/flutter_onnxruntime.dart';

import 'classification.dart';
import 'model_spec.dart';
import 'vision_model.dart';

/// Moteur ONNX Runtime, conservé pour brancher un modèle .onnx sans
/// modifier le code (ex. l'EfficientNet-B0 11 classes de la v2.0, décrit
/// par assets/models/onnx/onnx_model.json).
class OnnxVisionModel implements VisionModel {
  @override
  final ModelSpec spec;

  final OnnxRuntime _ort = OnnxRuntime();
  OrtSession? _session;
  List<String> _labels = const [];
  Future<void>? _loading;

  OnnxVisionModel(this.spec);

  @override
  List<String> get labels => _labels;

  @override
  Future<void> load() => _loading ??= _load().catchError((Object e) {
        _loading = null;
        throw e;
      });

  Future<void> _load() async {
    _labels = await VisionModel.loadLabels(spec);
    _session = await _ort.createSessionFromAsset(spec.modelAsset);
  }

  @override
  Future<ClassificationResult> classify(Uint8List imageBytes) async {
    await load();
    final session = _session!;
    final input = await VisionModel.prepare(imageBytes, spec);
    final tensor = await OrtValue.fromList(input, spec.inputShape);
    Map<String, OrtValue>? outputs;
    try {
      final watch = Stopwatch()..start();
      outputs = await session.run({spec.inputName: tensor});
      final output = outputs[spec.outputName];
      if (output == null) throw StateError('Sortie ONNX « ${spec.outputName} » introuvable.');
      final scores = flatten(await output.asList());
      watch.stop();
      return ClassificationResult.fromScores(scores, _labels, kind: spec.output, inferenceTime: watch.elapsed);
    } finally {
      await tensor.dispose();
      for (final v in outputs?.values ?? const <OrtValue>[]) {
        await v.dispose();
      }
    }
  }

  static List<double> flatten(dynamic output) {
    if (output is List) return [for (final e in output) ...flatten(e)];
    return [output is num ? output.toDouble() : double.parse('$output')];
  }

  @override
  Future<void> dispose() async {
    await _session?.close();
    _session = null;
    _loading = null;
  }
}
