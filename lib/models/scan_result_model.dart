/// Une classe candidate renvoyée par le modèle.
class Prediction {
  final String label;
  final double confidence;
  const Prediction(this.label, this.confidence);

  factory Prediction.fromJson(Map<String, dynamic> j) =>
      Prediction(j['label'] as String, (j['confidence'] as num).toDouble());

  Map<String, dynamic> toJson() => {'label': label, 'confidence': confidence};
}

/// État affiché d'une analyse.
///
/// 2.2.0 : [wrongCrop] ajouté (la feuille ne correspond pas à la culture
/// choisie). Correspondance avec [VisionDecision] : ok → [healthy] ou
/// [diseased] selon la fiche ; unknown → [uncertain] ; wrong_crop →
/// [wrongCrop]. [error] = analyse impossible (image illisible, modèle).
enum ScanStatus { healthy, diseased, uncertain, wrongCrop, error }

/// Statut d'une analyse, avec **les mêmes noms que le backend GREEN Web**.
///
/// Ajouté en 2.2.0 (classifier_v1).
enum VisionDecision {
  /// Culture cohérente et confiance ≥ seuil : diagnostic donné.
  ok('ok'),

  /// Culture cohérente mais confiance < seuil : image non reconnue.
  unknown('unknown'),

  /// La classe la plus probable appartient à une autre culture que celle
  /// choisie par l'utilisateur.
  wrongCrop('wrong_crop');

  /// Valeur échangée avec le backend et stockée dans l'historique.
  final String wire;
  const VisionDecision(this.wire);

  static VisionDecision? fromWire(String? value) {
    for (final d in values) {
      if (d.wire == value) return d;
    }
    return null;
  }
}


/// État de l'envoi de la photo vers GREEN Web (serveur o2switch).
enum SyncStatus { local, pending, sent, failed }

class SyncState {
  final SyncStatus status;
  final int? remoteAnalysisId;
  final String? remoteImagePath;
  final DateTime? sentAt;
  final String? lastError;
  final int attempts;

  /// Diagnostic recalculé par le serveur GREEN Web à la réception de la
  /// photo (son propre modèle), pour comparaison avec celui du téléphone.
  final String? serverDiagnosis;
  final double? serverConfidence;

  const SyncState({
    this.status = SyncStatus.local,
    this.remoteAnalysisId,
    this.remoteImagePath,
    this.sentAt,
    this.lastError,
    this.attempts = 0,
    this.serverDiagnosis,
    this.serverConfidence,
  });

  factory SyncState.fromJson(Map<String, dynamic>? j) {
    if (j == null) return const SyncState();
    return SyncState(
      status: SyncStatus.values.firstWhere(
        (s) => s.name == j['status'],
        orElse: () => SyncStatus.local,
      ),
      remoteAnalysisId: (j['remote_analysis_id'] as num?)?.toInt(),
      remoteImagePath: j['remote_image_path'] as String?,
      sentAt: DateTime.tryParse((j['sent_at'] as String?) ?? ''),
      lastError: j['last_error'] as String?,
      attempts: (j['attempts'] as num?)?.toInt() ?? 0,
      serverDiagnosis: j['server_diagnosis'] as String?,
      serverConfidence: (j['server_confidence'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'status': status.name,
        'remote_analysis_id': remoteAnalysisId,
        'remote_image_path': remoteImagePath,
        'sent_at': sentAt?.toIso8601String(),
        'last_error': lastError,
        'attempts': attempts,
        'server_diagnosis': serverDiagnosis,
        'server_confidence': serverConfidence,
      };
}

/// Résultat d'une analyse, enregistré dans l'historique (`scan_history_<id>.json`).
///
/// Les noms affichés (plante, maladie) ne sont pas figés ici : ils sont lus
/// dans la base de maladies hors ligne, dans la langue choisie, à partir de
/// [diseaseId]. [plantName] et [diseaseName] (français) servent de repli.
class ScanResultModel {
  final String id;

  /// Classe la plus probable du modèle (ex. « Corn leaf blight »), même
  /// quand la décision n'est pas « ok » (depuis la 2.2.0). Les analyses plus
  /// anciennes peuvent contenir 'uncertain' ou 'error'.
  final String label;

  /// Identifiant de la fiche dans assets/data/diseases.json.
  final String? diseaseId;
  final String? cropId;
  final String plantName;
  final String diseaseName;
  final double confidence;
  final List<Prediction> topPredictions;
  final ScanStatus status;

  /// Statut de la règle de décision, mêmes noms que le backend (ok,
  /// unknown, wrong_crop). null pour une erreur ou une analyse antérieure
  /// à la 2.2.0.
  final VisionDecision? decision;

  /// Culture choisie par l'utilisateur avant la photo (cassava, maize,
  /// tomato). null pour les analyses antérieures à la 2.2.0.
  final String? chosenCropId;

  /// Copie permanente de la photo dans le dossier de l'application.
  final String imagePath;
  final String? thumbPath;
  final DateTime scannedAt;

  /// 'camera' ou 'gallery'.
  final String source;
  final String modelVersion;
  final SyncState sync;

  const ScanResultModel({
    required this.id,
    required this.label,
    required this.diseaseId,
    this.cropId,
    required this.plantName,
    required this.diseaseName,
    required this.confidence,
    this.topPredictions = const [],
    required this.status,
    this.decision,
    this.chosenCropId,
    required this.imagePath,
    this.thumbPath,
    required this.scannedAt,
    this.source = 'camera',
    this.modelVersion = 'efficientnet-b0-11c',
    this.sync = const SyncState(),
  });

  bool get isHealthy => status == ScanStatus.healthy;
  bool get isDiseased => status == ScanStatus.diseased;
  bool get isUncertain => status == ScanStatus.uncertain;
  bool get isWrongCrop => status == ScanStatus.wrongCrop;
  bool get isError => status == ScanStatus.error;

  ScanResultModel copyWith({
    String? imagePath,
    String? thumbPath,
    SyncState? sync,
  }) {
    return ScanResultModel(
      id: id,
      label: label,
      diseaseId: diseaseId,
      cropId: cropId,
      plantName: plantName,
      diseaseName: diseaseName,
      confidence: confidence,
      topPredictions: topPredictions,
      status: status,
      decision: decision,
      chosenCropId: chosenCropId,
      imagePath: imagePath ?? this.imagePath,
      thumbPath: thumbPath ?? this.thumbPath,
      scannedAt: scannedAt,
      source: source,
      modelVersion: modelVersion,
      sync: sync ?? this.sync,
    );
  }

  factory ScanResultModel.fromJson(Map<String, dynamic> json) {
    // Format v2.
    if (json['schema'] == 2) {
      return ScanResultModel(
        id: json['id'] as String,
        label: json['label'] as String,
        diseaseId: json['disease_id'] as String?,
        cropId: json['crop_id'] as String?,
        plantName: (json['plant_name'] as String?) ?? '',
        diseaseName: (json['disease_name'] as String?) ?? '',
        confidence: (json['confidence'] as num).toDouble(),
        topPredictions: ((json['top'] as List?) ?? [])
            .map((e) => Prediction.fromJson(e as Map<String, dynamic>))
            .toList(),
        status: ScanStatus.values.firstWhere(
          (s) => s.name == json['status'],
          orElse: () => ScanStatus.uncertain,
        ),
        decision: VisionDecision.fromWire(json['decision'] as String?),
        chosenCropId: json['chosen_crop'] as String?,
        imagePath: (json['image_path'] as String?) ?? '',
        thumbPath: json['thumb_path'] as String?,
        scannedAt: DateTime.parse(json['scanned_at'] as String),
        source: (json['source'] as String?) ?? 'camera',
        modelVersion: (json['model_version'] as String?) ?? 'efficientnet-b0-11c',
        sync: SyncState.fromJson(json['sync'] as Map<String, dynamic>?),
      );
    }

    // Format v1 (avant la version 2.0.0) : disease_id contenait la classe
    // brute, la « gravité » était en réalité la confiance.
    final label = (json['disease_id'] as String?) ?? 'unknown';
    final name = (json['disease_name'] as String?) ?? '';
    final plants = ((json['affected_plants'] as List?) ?? []).map((e) => '$e').toList();
    final ScanStatus status;
    if (label == 'uncertain') {
      status = ScanStatus.uncertain;
    } else if (label == 'unknown') {
      status = ScanStatus.error;
    } else if (label.toLowerCase().contains('healthy')) {
      status = ScanStatus.healthy;
    } else {
      status = ScanStatus.diseased;
    }
    return ScanResultModel(
      id: json['id'] as String,
      label: label,
      diseaseId: null, // résolu à l'affichage via la classe brute
      plantName: plants.isNotEmpty ? plants.first : '',
      diseaseName: name,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
      status: status,
      imagePath: (json['image_url'] as String?) ?? '',
      scannedAt: DateTime.tryParse((json['scanned_at'] as String?) ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'schema': 2,
        'id': id,
        'label': label,
        'disease_id': diseaseId,
        'crop_id': cropId,
        'plant_name': plantName,
        'disease_name': diseaseName,
        'confidence': confidence,
        'top': topPredictions.map((p) => p.toJson()).toList(),
        'status': status.name,
        'decision': decision?.wire,
        'chosen_crop': chosenCropId,
        'image_path': imagePath,
        'thumb_path': thumbPath,
        'scanned_at': scannedAt.toIso8601String(),
        'source': source,
        'model_version': modelVersion,
        'sync': sync.toJson(),
      };
}
