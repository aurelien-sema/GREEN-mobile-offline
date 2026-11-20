import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../core/constants/app_constants.dart';
import '../models/disease_catalog_model.dart';
import '../models/scan_result_model.dart';
import '../providers/diseases_provider.dart';
import 'storage/scan_image_store.dart';
import 'vision/classification.dart';
import 'vision/decision_rule.dart';
import 'vision/vision_model.dart';

/// Analyse d'une photo de feuille : copie permanente de l'image, inférence
/// hors ligne (classifier_v1, TFLite), règle de décision (ok / unknown /
/// wrong_crop, voir [DecisionRule]) puis rattachement à la fiche de la base
/// de maladies.
///
/// 2.2.0 : la culture choisie par l'utilisateur avant la photo
/// ([chosenCropId]) est obligatoire.
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
    required String chosenCropId,
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
        chosenCropId: chosenCropId,
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
      chosenCropId: chosenCropId,
      id: id,
      imagePath: imagePath,
      thumbPath: thumbPath,
      scannedAt: now,
      source: source,
      modelVersion: modelId,
    );
  }

  /// Applique la règle de décision ([DecisionRule.decide]) et construit le
  /// résultat affiché. Séparé pour être testé sans modèle ni fichier.
  ///
  /// Modifié en 2.2.0 : l'ancienne règle (confiance < 70 % **ou** écart
  /// avec la 2e classe < 15 points → incertain) est remplacée par la règle
  /// commune avec le backend ; l'écart n'est plus utilisé.
  @visibleForTesting
  static ScanResultModel interpret(
    ClassificationResult result, {
    required DiseasesProvider catalog,
    required String chosenCropId,
    required String id,
    required String imagePath,
    String? thumbPath,
    required DateTime scannedAt,
    required String source,
    String modelVersion = 'unknown',
    double threshold = AppConstants.visionConfidenceThreshold,
  }) {
    final decision = DecisionRule.decide(result, chosenCrop: chosenCropId, threshold: threshold);
    final entry = catalog.findByModelLabel(result.label);
    final ok = decision == VisionDecision.ok;

    final status = switch (decision) {
      VisionDecision.wrongCrop => ScanStatus.wrongCrop,
      VisionDecision.unknown => ScanStatus.uncertain,
      // Chaque classe a sa fiche (vérifié par diseases_catalog_test) ; repli
      // sur le nom de la classe si la fiche manque.
      VisionDecision.ok => (entry?.type == DiseaseType.healthy || result.label.toLowerCase().contains('healthy'))
          ? ScanStatus.healthy
          : ScanStatus.diseased,
    };

    return ScanResultModel(
      id: id,
      label: result.label,
      diseaseId: ok ? entry?.id : null,
      // Culture affichée = culture choisie (pour wrong_crop : « cette
      // feuille ne ressemble pas à <culture choisie> »).
      cropId: chosenCropId,
      plantName: catalog.cropName(chosenCropId, 'fr'),
      diseaseName: entry?.name.of('fr') ?? result.label,
      confidence: result.confidence,
      topPredictions: result.top,
      status: status,
      decision: decision,
      chosenCropId: chosenCropId,
      imagePath: imagePath,
      thumbPath: thumbPath,
      scannedAt: scannedAt,
      source: source,
      modelVersion: modelVersion,
    );
  }
}

final visionService = VisionService();
