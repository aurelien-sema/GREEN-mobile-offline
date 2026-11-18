import '../../models/disease_catalog_model.dart';
import '../../models/scan_result_model.dart';
import '../../providers/diseases_provider.dart';

/// Libellés d'une analyse dans la langue courante, lus dans la base de
/// maladies (les anciennes analyses v1 sont retrouvées par leur classe brute).
class ScanLabels {
  ScanLabels._();

  static DiseaseCatalogModel? entry(ScanResultModel s, DiseasesProvider c) =>
      c.findById(s.diseaseId) ?? (s.isUncertain || s.isError ? null : c.findByModelLabel(s.label));

  static String plant(ScanResultModel s, DiseasesProvider c, String locale, String Function(String) t) {
    final cropId = s.cropId ?? entry(s, c)?.crops.firstOrNull ??
        c.findByModelLabel(s.topPredictions.firstOrNull?.label)?.crops.firstOrNull;
    if (cropId != null) return c.cropName(cropId, locale);
    return s.plantName.isNotEmpty ? s.plantName : t('unknownPlant');
  }

  static String title(ScanResultModel s, DiseasesProvider c, String locale, String Function(String) t) {
    return switch (s.status) {
      ScanStatus.healthy => t('healthyPlant'),
      ScanStatus.diseased => entry(s, c)?.name.of(locale) ?? s.diseaseName,
      ScanStatus.uncertain => t('uncertainResult'),
      ScanStatus.error => t('analysisError'),
    };
  }

  static String status(ScanResultModel s, String Function(String) t) => switch (s.status) {
        ScanStatus.healthy => t('statusHealthy'),
        ScanStatus.diseased => t('statusDiseased'),
        ScanStatus.uncertain => t('statusUncertain'),
        ScanStatus.error => t('statusError'),
      };

  static String severity(Severity s, String Function(String) t) => switch (s) {
        Severity.high => t('severityHigh'),
        Severity.moderate => t('severityModerate'),
        Severity.low => t('severityLow'),
        Severity.none => t('severityNone'),
      };

  /// Nom lisible d'une classe brute du modèle (« Corn Streak » → « Maïs —
  /// Virus de la striure du maïs »).
  static String labelName(String label, DiseasesProvider c, String locale) {
    final e = c.findByModelLabel(label);
    if (e == null) return label;
    final crop = e.crops.isEmpty ? '' : '${c.cropName(e.crops.first, locale)} — ';
    return '$crop${e.name.of(locale)}';
  }
}
