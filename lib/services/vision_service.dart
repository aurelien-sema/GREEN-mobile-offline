import 'dart:io';
import 'dart:convert';
import 'package:green_app/config/api_config.dart';
import 'package:green_app/models/scan_result_model.dart';
import 'package:http/http.dart' as http;
import 'package:green_app/services/tflite_service.dart';
import 'package:green_app/utils/french_translator.dart';
import 'package:uuid/uuid.dart';

/// Service pour l'intégration du modèle de vision par ordinateur Python
class VisionService {
  final Uuid _uuid = const Uuid();

  static const double confidenceThreshold = 0.75;

  /// Analyser une image de plante avec le modèle de vision (TFLite Offline)
  Future<ScanResultModel> analyzePlantImage(File imageFile) async {
    try {
      final tfliteResult = await tfliteService.classifyImage(imageFile);

      if (tfliteResult != null) {
        final String label = tfliteResult['label'] as String;
        final double confidence = tfliteResult['confidence'] as double;
        
        // Check if confidence meets threshold
        if (confidence < confidenceThreshold) {
          return ScanResultModel(
            id: _uuid.v4(),
            diseaseId: 'unknown',
            diseaseName: 'Image non reconnue',
            confidence: confidence,
            treatment: 'L\'image n\'est pas assez claire ou ne correspond pas à une plante connue.',
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
          // Fallback: Parse "Plant___Disease" format
          final parts = label.split('___');
          plantName = parts.isNotEmpty ? parts[0].replaceAll('_', ' ') : 'Inconnu';
          diseaseName = parts.length > 1 ? parts[1].replaceAll('_', ' ') : 'Inconnu';
        }

        return ScanResultModel(
          id: _uuid.v4(),
          diseaseId: label, // Use full label as ID
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

  /// Obtenir l'historique des scans
  Future<List<ScanResultModel>> getScanHistory() async {
    try {
      final url = Uri.parse(ApiConfig.getVisionUrl(ApiConfig.visionHistory));

      final response = await http.get(url).timeout(ApiConfig.connectionTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List<dynamic>;
        return data
            .map(
              (item) => ScanResultModel.fromJson(item as Map<String, dynamic>),
            )
            .toList();
      } else {
        throw Exception('Erreur de chargement de l\'historique');
      }
    } catch (e) {
      // Retourner des données de démo
      return _getMockHistory();
    }
  }

  /// Historique de démo
  List<ScanResultModel> _getMockHistory() {
    return [
      ScanResultModel(
        id: _uuid.v4(),
        diseaseId: 'demo_001',
        diseaseName: 'Mildiou',
        confidence: 0.85,
        treatment: 'Fongicide recommandé',
        imageUrl: '',
        scannedAt: DateTime(2024, 1, 15, 14, 30),
        affectedPlants: ['Tomate', 'Pomme de terre'],
      ),
      ScanResultModel(
        id: _uuid.v4(),
        diseaseId: 'demo_002',
        diseaseName: 'Oïdium',
        confidence: 0.92,
        treatment: 'Fongicide recommandé',
        imageUrl: '',
        scannedAt: DateTime(2024, 1, 12, 9, 15),
        affectedPlants: ['Courgette'],
      ),
    ];
  }
}
