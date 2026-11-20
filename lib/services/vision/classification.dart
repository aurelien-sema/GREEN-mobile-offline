import '../../models/scan_result_model.dart';

/// Résultat brut du classifieur, indépendant de la règle de décision.
///
/// Modifié en 2.2.0 (classifier_v1) : la sortie du modèle est déjà une
/// distribution de probabilités (somme = 1). Elle est gardée **telle
/// quelle** : plus de softmax (logits de l'ancien modèle ONNX), plus de
/// renormalisation, et plus d'« écart avec la 2e classe » (marge), retiré
/// de la règle de décision.
class ClassificationResult {
  /// Probabilités des classes, dans l'ordre de labels.txt.
  final List<double> probabilities;
  final List<String> labels;

  /// Classe la plus probable **parmi toutes les classes** du modèle.
  final int index;

  /// Durée de l'inférence seule (prétraitement exclu), pour les mesures.
  final Duration? inferenceTime;

  ClassificationResult({
    required this.probabilities,
    required this.labels,
    this.inferenceTime,
  })  : assert(probabilities.length == labels.length && labels.isNotEmpty),
        index = _argmax(probabilities);

  String get label => labels[index];

  /// Probabilité de [label].
  double get confidence => probabilities[index];

  /// Les trois classes les plus probables, de la plus à la moins probable
  /// (affichage uniquement ; la décision n'utilise que [index]).
  List<Prediction> get top {
    final order = List<int>.generate(probabilities.length, (i) => i)
      ..sort((a, b) => probabilities[b].compareTo(probabilities[a]));
    return order.take(3).map((i) => Prediction(labels[i], probabilities[i])).toList();
  }

  /// Sortie du modèle → résultat. Refuse une sortie de mauvaise taille ou
  /// contenant NaN / valeurs négatives (modèle mal chargé) au lieu de la
  /// « corriger ».
  static ClassificationResult fromProbabilities(
    List<double> probabilities,
    List<String> labels, {
    Duration? inferenceTime,
  }) {
    if (probabilities.length != labels.length) {
      throw StateError('Le modèle renvoie ${probabilities.length} classes, labels.txt en liste ${labels.length}.');
    }
    if (probabilities.any((p) => p.isNaN || p < 0)) {
      throw StateError('Sortie du modèle invalide (NaN ou valeur négative) : $probabilities');
    }
    return ClassificationResult(probabilities: List.unmodifiable(probabilities), labels: labels, inferenceTime: inferenceTime);
  }

  static int _argmax(List<double> values) {
    var best = 0;
    for (var i = 1; i < values.length; i++) {
      if (values[i] > values[best]) best = i;
    }
    return best;
  }
}
