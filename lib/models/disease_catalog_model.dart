/// Texte disponible en plusieurs langues : {'fr': ..., 'en': ...}.
/// Repli : langue demandée → anglais → français → première valeur.
class LocalizedText {
  final Map<String, String> values;
  const LocalizedText(this.values);

  factory LocalizedText.parse(Object? raw) {
    if (raw is String) return LocalizedText({'fr': raw});
    if (raw is Map) return LocalizedText(raw.map((k, v) => MapEntry('$k', '$v')));
    return const LocalizedText({});
  }

  bool get isEmpty => values.values.every((v) => v.trim().isEmpty);

  String of(String locale) {
    final v = values[locale] ?? values['en'] ?? values['fr'];
    if (v != null && v.isNotEmpty) return v;
    return values.values.isEmpty ? '' : values.values.first;
  }
}

/// Liste de textes en plusieurs langues.
class LocalizedList {
  final Map<String, List<String>> values;
  const LocalizedList(this.values);

  factory LocalizedList.parse(Object? raw) {
    if (raw is List) return LocalizedList({'fr': raw.map((e) => '$e').toList()});
    if (raw is Map) {
      return LocalizedList(raw.map((k, v) => MapEntry('$k', (v as List).map((e) => '$e').toList())));
    }
    return const LocalizedList({});
  }

  List<String> of(String locale) {
    final v = values[locale] ?? values['en'] ?? values['fr'];
    if (v != null && v.isNotEmpty) return v;
    return values.values.isEmpty ? const [] : values.values.first;
  }
}

/// Type de problème, pour l'icône et le filtre de la base de maladies.
enum DiseaseType { healthy, fungal, oomycete, bacterial, viral, pest, nematode, physiological }

enum Severity { none, low, moderate, high }

/// Une fiche de la base de maladies hors ligne (assets/data/diseases.json).
class DiseaseCatalogModel {
  final String id;
  final DiseaseType type;
  final List<String> crops;

  /// Classes du modèle de vision qui mènent à cette fiche.
  final List<String> modelLabels;
  final Severity severity;
  final LocalizedText name;
  final String scientificName;
  final List<String> aliases;
  final LocalizedList symptoms;
  final LocalizedText causes;
  final LocalizedList conditions;
  final LocalizedList actions;
  final LocalizedList prevention;
  final LocalizedText whenToSeekHelp;
  final LocalizedText lookalikes;

  const DiseaseCatalogModel({
    required this.id,
    required this.type,
    required this.crops,
    required this.modelLabels,
    required this.severity,
    required this.name,
    required this.scientificName,
    required this.aliases,
    required this.symptoms,
    required this.causes,
    required this.conditions,
    required this.actions,
    required this.prevention,
    required this.whenToSeekHelp,
    required this.lookalikes,
  });

  bool get isHealthy => type == DiseaseType.healthy;

  factory DiseaseCatalogModel.fromJson(Map<String, dynamic> j) {
    List<String> strings(Object? v) => (v as List?)?.map((e) => '$e').toList() ?? const [];
    return DiseaseCatalogModel(
      id: j['id'] as String,
      type: DiseaseType.values.firstWhere(
        (t) => t.name == j['type'],
        orElse: () => j['id'] == 'healthy' ? DiseaseType.healthy : DiseaseType.fungal,
      ),
      crops: strings(j['crops']),
      modelLabels: strings(j['modelLabels']),
      severity: Severity.values.firstWhere(
        (s) => s.name == j['severity'],
        orElse: () => Severity.moderate,
      ),
      name: LocalizedText.parse(j['name']),
      scientificName: (j['scientificName'] as String?) ?? '',
      aliases: strings(j['aliases']),
      symptoms: LocalizedList.parse(j['symptoms']),
      causes: LocalizedText.parse(j['causes']),
      conditions: LocalizedList.parse(j['conditions']),
      actions: LocalizedList.parse(j['actions']),
      prevention: LocalizedList.parse(j['prevention']),
      whenToSeekHelp: LocalizedText.parse(j['whenToSeekHelp']),
      lookalikes: LocalizedText.parse(j['lookalikes']),
    );
  }
}
