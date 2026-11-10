import 'dart:math' as math;

import '../../models/scan_result_model.dart';
import 'model_spec.dart';

/// Résultat brut du classifieur, indépendant du moteur.
class ClassificationResult {
  final String label;
  final int index;
  final double confidence;

  /// Les trois classes les plus probables, de la plus à la moins probable.
  final List<Prediction> top;

  /// Durée de l'inférence seule (prétraitement exclu), pour les mesures.
  final Duration? inferenceTime;

  const ClassificationResult({
    required this.label,
    required this.index,
    required this.confidence,
    required this.top,
    this.inferenceTime,
  });

  /// Écart entre la 1re et la 2e classe (la confiance si une seule classe).
  double get margin => top.length < 2 ? confidence : confidence - top[1].confidence;

  /// Sorties du modèle → probabilités triées (top 3).
  ///
  /// - [OutputKind.logits] : softmax stable ;
  /// - [OutputKind.probabilities] : valeurs négatives ou NaN ramenées à 0
  ///   puis renormalisées (le float16 peut donner une somme de 0,9999).
  static ClassificationResult fromScores(
    List<double> scores,
    List<String> labels, {
    required OutputKind kind,
    Duration? inferenceTime,
  }) {
    if (scores.length != labels.length) {
      throw StateError('Le modèle renvoie ${scores.length} classes, labels.txt en liste ${labels.length}.');
    }
    final probs = kind == OutputKind.logits ? softmax(scores) : normalize(scores);
    final order = List<int>.generate(probs.length, (i) => i)..sort((a, b) => probs[b].compareTo(probs[a]));
    return ClassificationResult(
      label: labels[order.first],
      index: order.first,
      confidence: probs[order.first].clamp(0.0, 1.0),
      top: order.take(3).map((i) => Prediction(labels[i], probs[i])).toList(),
      inferenceTime: inferenceTime,
    );
  }

  static List<double> softmax(List<double> logits) {
    final maxLogit = logits.reduce(math.max);
    final exps = logits.map((v) => math.exp(v - maxLogit)).toList();
    final sum = exps.fold<double>(0, (a, b) => a + b);
    if (sum == 0 || sum.isNaN) return List.filled(logits.length, 1 / logits.length);
    return exps.map((v) => v / sum).toList();
  }

  static List<double> normalize(List<double> probs) {
    final clean = probs.map((v) => v.isNaN || v < 0 ? 0.0 : v).toList();
    final sum = clean.fold<double>(0, (a, b) => a + b);
    if (sum == 0) return List.filled(probs.length, 1 / probs.length);
    return clean.map((v) => v / sum).toList();
  }
}
