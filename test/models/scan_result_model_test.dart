import 'package:flutter_test/flutter_test.dart';
import 'package:green_app/models/scan_result_model.dart';

void main() {
  group('ScanResultModel', () {
    Map<String, dynamic> json() => {
          'id': 's1',
          'disease_id': 'd1',
          'disease_name': 'Mildiou',
          'confidence': 0.87,
          'treatment': 'Fongicide',
          'image_url': 'assets/scan.png',
          'scanned_at': '2026-02-03T14:30:00.000',
          'affected_plants': ['Tomate', 'Pomme de terre'],
        };

    test('fromJson maps snake_case keys', () {
      final s = ScanResultModel.fromJson(json());
      expect(s.diseaseId, 'd1');
      expect(s.diseaseName, 'Mildiou');
      expect(s.confidence, 0.87);
      expect(s.imageUrl, 'assets/scan.png');
      expect(s.scannedAt, DateTime.parse('2026-02-03T14:30:00.000'));
      expect(s.affectedPlants, ['Tomate', 'Pomme de terre']);
    });

    test('severityLevel converts confidence to a 0-100 percentage', () {
      final s = ScanResultModel.fromJson(json()..['confidence'] = 0.5);
      expect(s.severityLevel, 50.0);
    });

    test('severityLevel is clamped to 100 when confidence exceeds 1', () {
      final s = ScanResultModel.fromJson(json()..['confidence'] = 1.5);
      expect(s.severityLevel, 100.0);
    });

    test('severityLevel is clamped to 0 for negative confidence', () {
      final s = ScanResultModel.fromJson(json()..['confidence'] = -0.2);
      expect(s.severityLevel, 0.0);
    });

    test('toJson round-trips through fromJson', () {
      final original = ScanResultModel.fromJson(json());
      final restored = ScanResultModel.fromJson(original.toJson());
      expect(restored.toJson(), original.toJson());
    });
  });
}
