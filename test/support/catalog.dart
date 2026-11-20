import 'dart:io';

import 'package:green_app/providers/diseases_provider.dart';

/// Base de maladies réelle (assets/data/diseases.json), sans rootBundle.
DiseasesProvider loadCatalog() {
  final p = DiseasesProvider();
  p.loadFromJson(File('assets/data/diseases.json').readAsStringSync());
  return p;
}

/// Classes du modèle actif (classifier_v1), puis celles de l'ancien modèle
/// à 11 classes (supprimé en 2.2.0) qui restent dans diseases.json
/// (modelLabels) uniquement pour afficher les anciennes analyses de
/// l'historique.
List<String> modelLabels() => [..._labels('assets/models/tflite/labels.txt'), ...legacyHistoryLabels];

const legacyHistoryLabels = ['Corn Brown Spots', 'Corn Mildew', 'Corn Streak', 'Corn Stripe'];

List<String> _labels(String path) => File(path)
    .readAsLinesSync()
    .map((l) => l.trim())
    .where((l) => l.isNotEmpty)
    .toList();
