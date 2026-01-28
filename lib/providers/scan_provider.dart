import 'dart:io';
import 'package:flutter/material.dart';
import 'package:green_app/models/scan_result_model.dart';
import 'package:green_app/services/vision_service.dart';

/// Provider pour gérer les scans de plantes
class ScanProvider with ChangeNotifier {
  final VisionService _visionService = VisionService();

  List<ScanResultModel> _scanHistory = [];
  ScanResultModel? _currentScanResult;
  bool _isScanning = false;
  String? _error;

  List<ScanResultModel> get scanHistory => _scanHistory;
  ScanResultModel? get currentScanResult => _currentScanResult;
  bool get isScanning => _isScanning;
  String? get error => _error;

  /// Analyser une image de plante
  Future<bool> analyzePlantImage(File imageFile) async {
    _isScanning = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _visionService.analyzePlantImage(imageFile);
      _currentScanResult = result;
      _scanHistory.insert(0, result);
      _isScanning = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isScanning = false;
      notifyListeners();
      debugPrint('Erreur d\'analyse: $e');
      return false;
    }
  }

  /// Charger l'historique des scans
  Future<void> loadScanHistory() async {
    try {
      _scanHistory = await _visionService.getScanHistory();
      notifyListeners();
    } catch (e) {
      debugPrint('Erreur de chargement de l\'historique: $e');
    }
  }

  /// Effacer le résultat actuel
  void clearCurrentResult() {
    _currentScanResult = null;
    _error = null;
    notifyListeners();
  }

  /// Obtenir les statistiques
  Map<String, int> getStatistics() {
    return {
      'totalScans': _scanHistory.length,
      'plantsScanned': _scanHistory
          .expand((scan) => scan.affectedPlants)
          .toSet()
          .length,
      'healthPercentage': _scanHistory.isEmpty
          ? 100
          : ((_scanHistory.where((scan) => scan.confidence > 0.8).length /
                        _scanHistory.length) *
                    100)
                .round(),
    };
  }
}
