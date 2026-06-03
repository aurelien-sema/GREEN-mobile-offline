/// Modèle pour les résultats de scan
class ScanResultModel {
  final String id;
  final String diseaseId;
  final String diseaseName;
  final double confidence;
  final String treatment;
  final String imageUrl;
  final DateTime scannedAt;
  final List<String> affectedPlants;

  ScanResultModel({
    required this.id,
    required this.diseaseId,
    required this.diseaseName,
    required this.confidence,
    required this.treatment,
    required this.imageUrl,
    required this.scannedAt,
    required this.affectedPlants,
  });

  /// Calcul du niveau de gravité en fonction de la confiance
  /// Formule : ((confidence - 0.55) * 100) / 0.45
  /// Plage de résultat : 0 à 100 (%)
  double get severityLevel {
    final confidenceThreshold = 0.4;
    final range = 0.45;
    if (confidence < confidenceThreshold) {
      return 0;
    }
    final severity = ((confidence - confidenceThreshold) * 100) / range;
    return severity > 100 ? 100 : severity;
  }

  factory ScanResultModel.fromJson(Map<String, dynamic> json) {
    return ScanResultModel(
      id: json['id'] as String,
      diseaseId: json['disease_id'] as String,
      diseaseName: json['disease_name'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      treatment: json['treatment'] as String,
      imageUrl: json['image_url'] as String,
      scannedAt: DateTime.parse(json['scanned_at'] as String),
      affectedPlants: (json['affected_plants'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'disease_id': diseaseId,
      'disease_name': diseaseName,
      'confidence': confidence,
      'treatment': treatment,
      'image_url': imageUrl,
      'scanned_at': scannedAt.toIso8601String(),
      'affected_plants': affectedPlants,
    };
  }
}
