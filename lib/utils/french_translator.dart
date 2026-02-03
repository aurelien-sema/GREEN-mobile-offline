import 'dart:convert';
import 'package:flutter/services.dart';

class FrenchLabelTranslator {
  static final FrenchLabelTranslator _instance = FrenchLabelTranslator._internal();
  
  factory FrenchLabelTranslator() {
    return _instance;
  }
  
  FrenchLabelTranslator._internal();
  
  Map<String, Map<String, String>>? _translationMap;
  
  /// Initialize the translator by loading french_labels.json
  Future<void> initialize() async {
    if (_translationMap != null) return;
    
    try {
      final jsonString = await rootBundle.loadString('assets/french_labels.json');
      final List<dynamic> jsonList = jsonDecode(jsonString);
      
      _translationMap = {};
      for (var item in jsonList) {
        final originalLabel = item['label_original'] as String;
        _translationMap![originalLabel] = {
          'plante': item['plante'] as String,
          'maladie': item['maladie'] as String,
        };
      }
    } catch (e) {
      print('Erreur lors du chargement des labels français: $e');
      _translationMap = {};
    }
  }
  
  /// Get the French translation for a label
  /// Returns a map with 'plante' and 'maladie' keys
  Map<String, String>? getTranslation(String originalLabel) {
    if (_translationMap == null) {
      print('Translator not initialized. Call initialize() first.');
      return null;
    }
    return _translationMap![originalLabel];
  }
  
  /// Get the plant name in French
  String? getPlantName(String originalLabel) {
    return getTranslation(originalLabel)?['plante'];
  }
  
  /// Get the disease name in French
  String? getDiseaseName(String originalLabel) {
    return getTranslation(originalLabel)?['maladie'];
  }
  
  /// Check if a label is 'healthy' (sain)
  bool isHealthy(String originalLabel) {
    final diseaseName = getDiseaseName(originalLabel);
    return diseaseName != null && (diseaseName.toLowerCase() == 'sain' || originalLabel.toLowerCase().contains('healthy'));
  }
}

// Singleton instance
final frenchTranslator = FrenchLabelTranslator();
