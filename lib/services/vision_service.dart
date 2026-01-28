import 'dart:io';
import 'dart:convert';
import 'package:green_app/config/api_config.dart';
import 'package:green_app/models/scan_result_model.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

/// Service pour l'intégration du modèle de vision par ordinateur Python
class VisionService {
  final Uuid _uuid = const Uuid();

  /// Analyser une image de plante avec le modèle de vision
  Future<ScanResultModel> analyzePlantImage(File imageFile) async {
    try {
      // Lire l'image et la convertir en base64
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      // Préparer la requête
      final url = Uri.parse(ApiConfig.getVisionUrl(ApiConfig.visionAnalyze));

      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'image': base64Image,
              'timestamp': DateTime.now().toIso8601String(),
            }),
          )
          .timeout(ApiConfig.connectionTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        // Parser la réponse du modèle Python
        return ScanResultModel(
          id: _uuid.v4(),
          diseaseId: data['disease_id'] as String? ?? _uuid.v4(),
          diseaseName: data['disease_name'] as String? ?? 'Maladie inconnue',
          confidence: (data['confidence'] as num?)?.toDouble() ?? 0.0,
          treatment:
              data['treatment'] as String? ?? 'Traitement non disponible',
          imageUrl: imageFile.path,
          scannedAt: DateTime.now(),
          affectedPlants:
              (data['affected_plants'] as List<dynamic>?)
                  ?.map((e) => e as String)
                  .toList() ??
              [],
        );
      } else {
        throw Exception(
          'Erreur API: ${response.statusCode} - ${response.body}',
        );
      }
    } on SocketException {
      // Mode démo si l'API n'est pas disponible
      return _getMockScanResult(imageFile);
    } catch (e) {
      // Mode démo en cas d'erreur
      return _getMockScanResult(imageFile);
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

  /// Données de démo pour les tests (quand l'API Python n'est pas disponible)
  ScanResultModel _getMockScanResult(File imageFile) {
    return ScanResultModel(
      id: _uuid.v4(),
      diseaseId: 'demo_001',
      diseaseName: 'Mildiou',
      confidence: 0.85,
      treatment: 'Fongicide recommandé',
      imageUrl: imageFile.path,
      scannedAt: DateTime.now(),
      affectedPlants: ['Tomate', 'Pomme de terre'],
    );
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
