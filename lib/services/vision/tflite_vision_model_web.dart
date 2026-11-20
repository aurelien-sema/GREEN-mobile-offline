import 'package:flutter/foundation.dart';

import 'classification.dart';
import 'model_spec.dart';
import 'vision_model.dart';

/// Remplaçant web de TfliteVisionModel (aperçu de l'interface dans Chrome).
///
/// tflite_flutter repose sur dart:ffi, indisponible sur le web : vision_model.dart
/// importe ce fichier à la place de tflite_vision_model.dart uniquement pour
/// une compilation web. Android et iOS utilisent toujours le vrai moteur.
/// L'analyse d'une photo échoue ici avec un message clair.
class TfliteVisionModel implements VisionModel {
  @override
  final ModelSpec spec;

  TfliteVisionModel(this.spec);

  @override
  List<String> get labels => const [];

  @override
  Future<void> load() async => throw UnsupportedError(_message);

  @override
  Future<ClassificationResult> classify(Uint8List imageBytes) async => throw UnsupportedError(_message);

  @override
  Future<void> dispose() async {}

  static const _message = 'Analyse hors ligne indisponible dans l\'aperçu web (TFLite non pris en charge).';
}
