import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../models/disease_catalog_model.dart';

/// Provider qui charge et met à disposition la base de maladies en local (assets)
class DiseasesProvider with ChangeNotifier {
  final List<DiseaseCatalogModel> _diseases = [];
  bool _loaded = false;

  List<DiseaseCatalogModel> get diseases => List.unmodifiable(_diseases);

  /// Charge une fois depuis les assets (caché ensuite)
  Future<void> load() async {
    if (_loaded) return;
    try {
      final raw = await rootBundle.loadString('assets/data/diseases.json');
      final data = jsonDecode(raw) as List<dynamic>;
      _diseases.clear();
      _diseases.addAll(
        data.map((e) => DiseaseCatalogModel.fromJson(e as Map<String, dynamic>)).toList(),
      );
      _loaded = true;
      notifyListeners();
    } catch (e) {
      // Keep empty list if loading fails; callers may fallback gracefully
      debugPrint('Error loading diseases asset: $e');
    }
  }

  /// Recherche simple par nom (tolère accents, underscores, casse)
  DiseaseCatalogModel? findByName(String name) {
    final n = _normalize(name);
    for (final d in _diseases) {
      if (_normalize(d.name) == n) return d;
      if (d.aliases.any((a) => _normalize(a) == n)) return d;
    }
    // fallback: contains
    for (final d in _diseases) {
      if (_normalize(d.name).contains(n)) return d;
      if (d.aliases.any((a) => _normalize(a).contains(n))) return d;
    }
    return null;
  }

  /// Recherche / filtre par texte
  List<DiseaseCatalogModel> search(String query) {
    final q = _normalize(query);
    if (q.isEmpty) return diseases;

    return _diseases.where((d) {
      return _normalize(d.name).contains(q) || _normalize(d.scientificName).contains(q) || d.affectedPlants.any((p) => _normalize(p).contains(q));
    }).toList();
  }

  String _normalize(String s) {
    // Small normalization: remove underscores, lowercase, remove accents common ones
    var x = s.toLowerCase().replaceAll('_', ' ').trim();
    const accents = {
      'à': 'a', 'á': 'a', 'â': 'a', 'ä': 'a', 'ã': 'a', 'å': 'a',
      'è': 'e', 'é': 'e', 'ê': 'e', 'ë': 'e',
      'ì': 'i', 'í': 'i', 'î': 'i', 'ï': 'i',
      'ò': 'o', 'ó': 'o', 'ô': 'o', 'ö': 'o', 'õ': 'o',
      'ù': 'u', 'ú': 'u', 'û': 'u', 'ü': 'u',
      'ç': 'c', 'ñ': 'n'
    };
    accents.forEach((k, v) {
      x = x.replaceAll(k, v);
    });
    return x;
  }
}
