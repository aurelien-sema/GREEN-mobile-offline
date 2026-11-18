import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../core/constants/app_constants.dart';
import '../models/disease_catalog_model.dart';
import '../models/scan_result_model.dart';
import '../providers/diseases_provider.dart';
import 'storage/scan_image_store.dart';
import 'vision/classification.dart';
import 'vision/vision_model.dart';

/// Analyse d'une photo de plante : copie permanente de l'image, inférence
/// hors ligne (TFLite ou ONNX selon assets/models/active_model.json), puis
/// rattachement à la fiche de la base de maladies.
class VisionService {
  final VisionEngine _engine;
  final ScanImageStore _images;

  VisionService({VisionEngine? engine, ScanImageStore? images})
      : _engine = engine ?? visionEngine,
        _images = images ?? scanImageStore;

  Future<ScanResultModel> analyze(
    File photo, {
    required DiseasesProvider catalog,
    required String source,
  }) async {
    final id = const Uuid().v4();
    final now = DateTime.now();
    await catalog.load();

    // La copie permanente et l'inférence tournent en parallèle.
    final stored = _images.persist(photo, id);
    final modelId = await _engine.activeModelId();
    ClassificationResult? result;
    Object? failure;
    try {
      result = await _engine.classify(await photo.readAsBytes());
    } catch (e) {
      failure = e;
      debugPrint('Analyse impossible : $e');
    }
    final (imagePath, thumbPath) = await stored;

    if (result == null) {
      return ScanResultModel(
        id: id,
        label: 'error',
        diseaseId: null,
        plantName: '',
        diseaseName: '',
        confidence: 0,
        status: ScanStatus.error,
        imagePath: imagePath,
        thumbPath: thumbPath,
        scannedAt: now,
        source: source,
        modelVersion: modelId,
        sync: SyncState(lastError: '$failure'),
      );
    }
    return interpret(
      result,
      catalog: catalog,
      id: id,
      imagePath: imagePath,
      thumbPath: thumbPath,
      scannedAt: now,
      source: source,
      modelVersion: modelId,
    );
  }

  /// Règle de décision, séparée pour être testée sans modèle ni fichier :
  /// - confiance < 70 % ou écart avec la 2e classe < 15 points → incertain
  ///   (le modèle hésite : on montre les possibilités, pas un diagnostic) ;
  /// - sinon, la classe est rattachée à sa fiche par correspondance exacte.
  @visibleForTesting
  static ScanResultModel interpret(
    ClassificationResult result, {
    required DiseasesProvider catalog,
    required String id,
    required String imagePath,
    String? thumbPath,
    required DateTime scannedAt,
    required String source,
    String modelVersion = 'unknown',
  }) {
    final entry = catalog.findByModelLabel(result.label);
    final cropId = entry?.crops.isNotEmpty == true ? entry!.crops.first : null;
    final confident = result.confidence >= AppConstants.visionConfidenceThreshold &&
        result.margin >= AppConstants.visionMarginThreshold;

    final ScanStatus status;
    if (!confident || entry == null) {
      status = ScanStatus.uncertain;
    } else if (entry.type == DiseaseType.healthy) {
      status = ScanStatus.healthy;
    } else {
      status = ScanStatus.diseased;
    }

    return ScanResultModel(
      id: id,
      label: confident ? result.label : 'uncertain',
      diseaseId: confident ? entry?.id : null,
      cropId: cropId,
      plantName: cropId == null ? '' : catalog.cropName(cropId, 'fr'),
      diseaseName: entry?.name.of('fr') ?? result.label,
      confidence: result.confidence,
      topPredictions: result.top,
      status: status,
      imagePath: imagePath,
      thumbPath: thumbPath,
      scannedAt: scannedAt,
      source: source,
      modelVersion: modelVersion,
    );
  }
}

final visionService = VisionService();
