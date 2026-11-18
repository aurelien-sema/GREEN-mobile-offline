import 'package:flutter_test/flutter_test.dart';
import 'package:green_app/models/scan_result_model.dart';

void main() {
  test('aller-retour JSON v2', () {
    final s = ScanResultModel(
      id: 'a',
      label: 'Corn Streak',
      diseaseId: 'maize-streak-virus',
      cropId: 'maize',
      plantName: 'Maïs',
      diseaseName: 'Virus de la striure du maïs',
      confidence: 0.9,
      topPredictions: const [Prediction('Corn Streak', 0.9)],
      status: ScanStatus.diseased,
      imagePath: '/x/a.jpg',
      thumbPath: '/x/a_thumb.jpg',
      scannedAt: DateTime.utc(2026, 11, 7, 8),
      source: 'gallery',
      sync: const SyncState(status: SyncStatus.sent, remoteAnalysisId: 42),
    );
    final back = ScanResultModel.fromJson(s.toJson());
    expect(back.diseaseId, s.diseaseId);
    expect(back.status, ScanStatus.diseased);
    expect(back.sync.status, SyncStatus.sent);
    expect(back.sync.remoteAnalysisId, 42);
    expect(back.topPredictions.single.label, 'Corn Streak');
  });

  test('lecture des analyses v1 (avant la mise à jour)', () {
    final v1 = ScanResultModel.fromJson({
      'id': 'old',
      'disease_id': 'Tomato healthy',
      'disease_name': 'Saine',
      'confidence': 0.95,
      'treatment': '...',
      'image_url': '/cache/scaled_123.jpg',
      'scanned_at': '2026-07-01T10:00:00.000',
      'affected_plants': ['Tomate'],
    });
    expect(v1.status, ScanStatus.healthy);
    expect(v1.plantName, 'Tomate');
    expect(v1.imagePath, '/cache/scaled_123.jpg');
    expect(ScanResultModel.fromJson({...v1.toJson()}).status, ScanStatus.healthy);
    expect(ScanResultModel.fromJson({'id': 'u', 'disease_id': 'uncertain', 'confidence': 0.4, 'scanned_at': '2026-07-01T10:00:00'}).isUncertain, isTrue);
  });
}
