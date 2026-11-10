import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../models/disease_catalog_model.dart';

/// Base de maladies hors ligne (assets/data/diseases.json, format v2).
class DiseasesProvider with ChangeNotifier {
  static const assetPath = 'assets/data/diseases.json';

  final List<DiseaseCatalogModel> _diseases = [];
  final Map<String, LocalizedText> _crops = {};
  final Map<String, DiseaseCatalogModel> _byLabel = {};
  bool _loaded = false;
  Future<void>? _loading;
  Set<String> _activeLabels = const {};

  List<DiseaseCatalogModel> get diseases => List.unmodifiable(_diseases);
  Map<String, LocalizedText> get crops => Map.unmodifiable(_crops);
  bool get isLoaded => _loaded;

  Future<void> load() => _loading ??= _load();

  Future<void> _load() async {
    try {
      final raw = await rootBundle.loadString(assetPath);
      loadFromJson(raw);
    } catch (e) {
      debugPrint('Base de maladies illisible : $e');
    }
  }

  /// Exposé pour les tests.
  @visibleForTesting
  void loadFromJson(String raw) {
    final data = jsonDecode(raw) as Map<String, dynamic>;
    _diseases.clear();
    _crops.clear();
    _byLabel.clear();
    (data['crops'] as Map<String, dynamic>? ?? {}).forEach((id, v) {
      _crops[id] = LocalizedText.parse(v);
    });
    final list = data['diseases'] as List<dynamic>? ?? [];
    for (var i = 0; i < list.length; i++) {
      try {
        final d = DiseaseCatalogModel.fromJson(list[i] as Map<String, dynamic>);
        _diseases.add(d);
        for (final l in d.modelLabels) {
          _byLabel[l.toLowerCase()] = d;
        }
      } catch (e) {
        debugPrint('diseases.json, entrée n°$i ignorée : $e');
      }
    }
    _loaded = true;
    notifyListeners();
  }

  DiseaseCatalogModel? findById(String? id) {
    if (id == null) return null;
    for (final d in _diseases) {
      if (d.id == id) return d;
    }
    return null;
  }

  /// Fiche correspondant à une classe du modèle de vision (correspondance
  /// explicite, plus de recherche approximative par nom).
  DiseaseCatalogModel? findByModelLabel(String? label) =>
      label == null ? null : _byLabel[label.toLowerCase()];

  /// Classes du modèle de vision actif (assets/models/active_model.json).
  void setActiveModelLabels(List<String> labels) {
    _activeLabels = labels.map((l) => l.toLowerCase()).toSet();
    notifyListeners();
  }

  /// La fiche correspond-elle à une classe que le modèle ACTIF sait
  /// reconnaître ? (Les correspondances d'un autre modèle, ex. ONNX, restent
  /// dans diseases.json mais ne sont pas annoncées.)
  bool isDetectable(DiseaseCatalogModel d) =>
      d.modelLabels.any((l) => _activeLabels.contains(l.toLowerCase()));

  String cropName(String cropId, String locale) => _crops[cropId]?.of(locale) ?? cropId;

  /// Recherche plein texte (nom, nom scientifique, alias, cultures), insensible
  /// à la casse et aux accents, avec filtres facultatifs.
  List<DiseaseCatalogModel> search(
    String query, {
    required String locale,
    String? cropId,
    DiseaseType? type,
  }) {
    final q = normalize(query);
    return _diseases.where((d) {
      if (d.isHealthy && cropId == null && q.isEmpty) return false;
      if (cropId != null && !d.crops.contains(cropId)) return false;
      if (type != null && d.type != type) return false;
      if (q.isEmpty) return true;
      final haystack = [
        d.name.of(locale),
        d.name.of('fr'),
        d.name.of('en'),
        d.scientificName,
        ...d.aliases,
        ...d.crops.map((c) => cropName(c, locale)),
      ].map(normalize).join(' ');
      return q.split(' ').every(haystack.contains);
    }).toList()
      ..sort((a, b) => normalize(a.name.of(locale)).compareTo(normalize(b.name.of(locale))));
  }

  static String normalize(String s) {
    var x = s.toLowerCase().replaceAll('_', ' ').trim();
    const accents = {
      'à': 'a', 'á': 'a', 'â': 'a', 'ä': 'a', 'ã': 'a',
      'è': 'e', 'é': 'e', 'ê': 'e', 'ë': 'e',
      'ì': 'i', 'í': 'i', 'î': 'i', 'ï': 'i',
      'ò': 'o', 'ó': 'o', 'ô': 'o', 'ö': 'o',
      'ù': 'u', 'ú': 'u', 'û': 'u', 'ü': 'u',
      'ç': 'c', 'ñ': 'n', 'œ': 'oe',
    };
    accents.forEach((k, v) => x = x.replaceAll(k, v));
    return x.replaceAll(RegExp(r'\s+'), ' ');
  }
}
