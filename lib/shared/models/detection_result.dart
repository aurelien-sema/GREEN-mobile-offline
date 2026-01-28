class DetectionResult {
  final String diseaseId;
  final String diseaseName;
  final double confidence;
  final String description;
  final List<String> treatments;
  final String severity;
  final DateTime detectionDate;

  DetectionResult({
    required this.diseaseId,
    required this.diseaseName,
    required this.confidence,
    required this.description,
    required this.treatments,
    required this.severity,
    required this.detectionDate,
  });

  Map<String, dynamic> toJson() => {
    'diseaseId': diseaseId,
    'diseaseName': diseaseName,
    'confidence': confidence,
    'description': description,
    'treatments': treatments,
    'severity': severity,
    'detectionDate': detectionDate.toIso8601String(),
  };

  factory DetectionResult.fromJson(Map<String, dynamic> json) =>
      DetectionResult(
        diseaseId: json['diseaseId'] as String,
        diseaseName: json['diseaseName'] as String,
        confidence: (json['confidence'] as num).toDouble(),
        description: json['description'] as String,
        treatments: List<String>.from(json['treatments'] as List),
        severity: json['severity'] as String,
        detectionDate: DateTime.parse(json['detectionDate'] as String),
      );
}
