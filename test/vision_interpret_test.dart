import 'package:flutter_test/flutter_test.dart';
import 'package:green_app/models/scan_result_model.dart';
import 'package:green_app/services/vision/classification.dart';
import 'package:green_app/services/vision_service.dart';

import 'support/catalog.dart';

ClassificationResult _result(List<(String, double)> top) => ClassificationResult(
      label: top.first.$1,
      index: 0,
      confidence: top.first.$2,
      top: top.map((p) => Prediction(p.$1, p.$2)).toList(),
    );

void main() {
  final catalog = loadCatalog();
  ScanResultModel interpret(ClassificationResult r) => VisionService.interpret(
        r,
        catalog: catalog,
        id: 'x',
        imagePath: '/tmp/x.jpg',
        scannedAt: DateTime(2026, 11, 7),
        source: 'camera',
      );

  test('classe malade sûre → maladie probable, fiche et culture rattachées', () {
    final s = interpret(_result([('Corn leaf blight', 0.91), ('Corn Yellowing', 0.05), ('Corn Healthy', 0.02)]));
    expect(s.status, ScanStatus.diseased);
    expect(s.diseaseId, 'maize-northern-leaf-blight');
    expect(s.cropId, 'maize');
    expect(s.plantName, 'Maïs');
  });

  test('nouvelles classes du modèle TFLite : taches brunes et manioc sain', () {
    final spot = interpret(_result([('Cassava Brown Leaf Spot', 0.88), ('Cassava Mosaic', 0.07)]));
    expect(spot.status, ScanStatus.diseased);
    expect(spot.diseaseId, 'cassava-brown-leaf-spot');
    expect(spot.cropId, 'cassava');
    final healthy = interpret(_result([('Cassava Healthy', 0.95), ('Cassava Mosaic', 0.03)]));
    expect(healthy.status, ScanStatus.healthy);
    expect(healthy.diseaseId, 'cassava-healthy');
  });

  test('classe saine sûre → plante saine', () {
    final s = interpret(_result([('Tomato healthy', 0.97), ('Tomato Brown Spots', 0.02)]));
    expect(s.status, ScanStatus.healthy);
    expect(s.cropId, 'tomato');
  });

  test('confiance < 70 % → incertain, sans diagnostic', () {
    final s = interpret(_result([('Cassava Mosaic', 0.62), ('Cassava Brown Leaf Spot', 0.2)]));
    expect(s.status, ScanStatus.uncertain);
    expect(s.diseaseId, isNull);
    expect(s.topPredictions, hasLength(2));
  });

  test('deux classes trop proches → incertain même au-dessus de 70 %', () {
    final s = interpret(_result([('Tomato blight leaf', 0.72), ('Tomato Brown Spots', 0.60)]));
    expect(s.status, ScanStatus.uncertain);
  });

  test('une plante saine reconnue à 99 % n\'est plus présentée comme « gravité très élevée »', () {
    final healthy = interpret(_result([('Corn Healthy', 0.99), ('Corn Yellowing', 0.005)]));
    expect(healthy.isHealthy, isTrue);
    expect(catalog.findById('maize-healthy')!.severity.name, 'none');
  });
}
