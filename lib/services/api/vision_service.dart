import 'package:dio/dio.dart';
import '../../core/constants/app_constants.dart';
import '../../shared/models/detection_result.dart';

class VisionService {
  late final Dio _dio;

  VisionService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.apiBaseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ),
    );

    _dio.interceptors.add(
      LogInterceptor(requestBody: true, responseBody: true),
    );
  }

  /// Détecter une maladie à partir d'une image
  ///
  /// [imagePath] : Chemin local de l'image ou URL
  /// [fileName] : Nom du fichier (optionnel)
  Future<DetectionResult> detectDisease({
    required String imagePath,
    String? fileName,
  }) async {
    try {
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(
          imagePath,
          filename: fileName ?? 'plant_image.jpg',
        ),
      });

      final response = await _dio.post(
        AppConstants.visionApiEndpoint,
        data: formData,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return DetectionResult.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw Exception('Erreur API Vision: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw Exception('Erreur lors de la détection: $e');
    }
  }

  /// Obtenir la liste des maladies détectées
  Future<List<DetectionResult>> getDetectionHistory({
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await _dio.get(
        '${AppConstants.visionApiEndpoint}/history',
        queryParameters: {'limit': limit, 'offset': offset},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data as List<dynamic>;
        return data
            .map((e) => DetectionResult.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Erreur lors de la récupération de l\'historique');
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw Exception('Erreur: $e');
    }
  }

  String _handleDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return 'Délai d\'attente dépassé - Vérifiez votre connexion';
      case DioExceptionType.receiveTimeout:
        return 'Délai de réception dépassé';
      case DioExceptionType.connectionError:
        return 'Erreur de connexion - Serveur indisponible';
      default:
        return 'Erreur réseau: ${e.message}';
    }
  }
}
