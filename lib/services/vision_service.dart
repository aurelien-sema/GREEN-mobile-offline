import 'dart:io';
import 'package:green_app/core/constants/app_constants.dart';
import 'package:green_app/models/scan_result_model.dart';
import 'package:green_app/services/tflite_service.dart';
import 'package:green_app/utils/french_translator.dart';
import 'package:uuid/uuid.dart';

/// Service pour l'intégration du modèle de vision par ordinateur (TFLite, offline)
class VisionService {
  final Uuid _uuid = const Uuid();

  /// En dessous de ce seuil, le résultat n'est pas présenté comme un
  /// diagnostic fiable (voir AppConstants.visionConfidenceThreshold, valeur
  /// partagée avec ScanResultModel.severityLevel pour rester cohérentes).
  static const double confidenceThreshold = AppConstants.visionConfidenceThreshold;

  /// Analyser une image de plante avec le modèle de vision (TFLite Offline)
  Future<ScanResultModel> analyzePlantImage(File imageFile) async {
    try {
      final tfliteResult = await tfliteService.classifyImage(imageFile);

      if (tfliteResult != null) {
        final String label = tfliteResult['label'] as String;
        final double confidence = tfliteResult['confidence'] as double;

        if (confidence < confidenceThreshold) {
          return ScanResultModel(
            id: _uuid.v4(),
            diseaseId: 'uncertain',
            diseaseName: 'Résultat incertain',
            confidence: confidence,
            treatment:
                'La confiance du modèle est trop faible (${(confidence * 100).toStringAsFixed(0)}%) '
                'pour proposer un diagnostic fiable. Reprenez la photo en gros plan, '
                'bien éclairée, sur la feuille affectée.',
            imageUrl: imageFile.path,
            scannedAt: DateTime.now(),
            affectedPlants: [],
          );
        }

        // Get French translation from translator
        final translation = frenchTranslator.getTranslation(label);
        String plantName = 'Inconnu';
        String diseaseName = 'Inconnu';

        if (translation != null) {
          plantName = translation['plante'] ?? 'Inconnu';
          diseaseName = translation['maladie'] ?? 'Inconnu';
        } else {
          // Filet de sécurité si un label n'a pas (encore) de traduction dans
          // french_labels.json : on tente d'abord l'ancienne convention
          // PlantVillage "Plante___Maladie" (triple underscore), puis la
          // convention actuelle "Culture_Maladie" (underscore simple).
          List<String> parts = label.split('___');
          if (parts.length < 2) {
            final idx = label.indexOf('_');
            parts = idx == -1 ? [label] : [label.substring(0, idx), label.substring(idx + 1)];
          }
          plantName = parts.isNotEmpty ? parts[0].replaceAll('_', ' ') : 'Inconnu';
          diseaseName = parts.length > 1 ? parts[1].replaceAll('_', ' ') : 'Inconnu';
        }

        return ScanResultModel(
          id: _uuid.v4(),
          diseaseId: label,
          diseaseName: diseaseName,
          confidence: confidence,
          treatment: 'Consultez Green Bot pour des recommandations précises.',
          imageUrl: imageFile.path,
          scannedAt: DateTime.now(),
          affectedPlants: [plantName],
        );
      } else {
        throw Exception('Aucun résultat du modèle');
      }
    } catch (e) {
      // Return unknown on error instead of mock for production feel
      return ScanResultModel(
        id: _uuid.v4(),
        diseaseId: 'unknown',
        diseaseName: 'Erreur d\'analyse',
        confidence: 0,
        treatment: 'Une erreur est survenue lors de l\'analyse. Veuillez réessayer.',
        imageUrl: imageFile.path,
        scannedAt: DateTime.now(),
        affectedPlants: [],
      );
    }
  }
}
