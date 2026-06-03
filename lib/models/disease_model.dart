/// Modèle pour les maladies détectées
class DiseaseModel {
  final String id;
  final String name;
  final List<String> affectedPlants;
  final DateTime detectedAt;
  final String treatment;
  final double confidence;
  final String? imageUrl;
  final DiseaseType type;

  DiseaseModel({
    required this.id,
    required this.name,
    required this.affectedPlants,
    required this.detectedAt,
    required this.treatment,
    required this.confidence,
    this.imageUrl,
    required this.type,
  });

  /// Calcul du niveau de gravité en fonction de la confiance
  /// Formule : ((confidence - 0.55) * 100) / 45
  /// Plage de résultat : 0 à 100 (%)
  double get severityLevel {
    final confidenceThreshold = 0.55;
    final range = 45;
    if (confidence < confidenceThreshold) {
      return 0;
    }
    final severity = ((confidence - confidenceThreshold) * 100) / range;
    return severity > 100 ? 100 : severity;
  }

  factory DiseaseModel.fromJson(Map<String, dynamic> json) {
    return DiseaseModel(
      id: json['id'] as String,
      name: json['name'] as String,
      affectedPlants: (json['affected_plants'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      detectedAt: DateTime.parse(json['detected_at'] as String),
      treatment: json['treatment'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      imageUrl: json['image_url'] as String?,
      type: DiseaseType.fromString(json['type'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'affected_plants': affectedPlants,
      'detected_at': detectedAt.toIso8601String(),
      'treatment': treatment,
      'confidence': confidence,
      'image_url': imageUrl,
      'type': type.toString(),
    };
  }
}

/// Types de maladies
enum DiseaseType {
  fungal,
  bacterial,
  viral,
  pest,
  nutritional,
  unknown;

  static DiseaseType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'fungal':
        return DiseaseType.fungal;
      case 'bacterial':
        return DiseaseType.bacterial;
      case 'viral':
        return DiseaseType.viral;
      case 'pest':
        return DiseaseType.pest;
      case 'nutritional':
        return DiseaseType.nutritional;
      default:
        return DiseaseType.unknown;
    }
  }

  @override
  String toString() {
    return name;
  }
}
