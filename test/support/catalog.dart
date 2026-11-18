import 'dart:io';

import 'package:green_app/providers/diseases_provider.dart';

/// Base de maladies réelle (assets/data/diseases.json), sans rootBundle.
DiseasesProvider loadCatalog() {
  final p = DiseasesProvider();
  p.loadFromJson(File('assets/data/diseases.json').readAsStringSync());
  return p;
}

/// Classes du modèle actif (TFLite) puis du modèle ONNX conservé.
List<String> modelLabels() => [..._labels('assets/models/tflite/labels.txt'), ..._labels('assets/models/onnx/labels.txt')];

List<String> _labels(String path) => File(path)
    .readAsLinesSync()
    .map((l) => l.trim())
    .where((l) => l.isNotEmpty)
    .toList();
