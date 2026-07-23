import 'dart:io';
import 'package:green_app/core/constants/app_constants.dart';
import 'package:green_app/models/scan_result_model.dart';
import 'package:green_app/services/onnx_service.dart';
import 'package:green_app/utils/french_translator.dart';
import 'package:uuid/uuid.dart';

/// Service pour l'intégration du modèle de vision par ordinateur (ONNX, offline)
class VisionService {
  final Uuid _uuid = const Uuid();

  /// En dessous de ce seuil, le résultat n'est pas présenté comme un
  /// diagnostic fiable (voir AppConstants.visionConfidenceThreshold, valeur
  /// partagée avec ScanResultModel.severityLevel pour rester cohérentes).
  static const double confidenceThreshold = AppConstants.visionConfidenceThreshold;

  /// Analyser une image de plante avec le modèle de vision (ONNX Offline)
  Future<ScanResultModel> analyzePlantImage(File imageFile) async {
    try {
      final onnxResult = await onnxService.classifyImage(imageFile);

      if (onnxResult != null) {
        final String label = onnxResult['label'] as String;
        final double confidence = onnxResult['confidence'] as double;

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
          // french_labels.json : le premier mot est la culture ("Corn Brown
          // Spots" -> Corn / Brown Spots). On tolère aussi les anciennes
          // conventions à underscores ("Plante___Maladie" / "Culture_Maladie").
          final normalized = label.replaceAll('___', ' ').replaceAll('_', ' ').trim();
          final idx = normalized.indexOf(' ');
          if (idx == -1) {
            plantName = normalized;
            diseaseName = 'Inconnu';
          } else {
            plantName = normalized.substring(0, idx);
            diseaseName = normalized.substring(idx + 1);
          }
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
