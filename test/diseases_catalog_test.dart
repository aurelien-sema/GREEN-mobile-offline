import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:green_app/models/disease_catalog_model.dart';

import 'support/catalog.dart';

void main() {
  final catalog = loadCatalog();

  test('chaque classe des modèles (TFLite et ONNX) mène à exactement une fiche', () {
    for (final label in modelLabels().toSet()) {
      final hits = catalog.diseases.where((d) => d.modelLabels.contains(label)).toList();
      expect(hits, hasLength(1), reason: label);
    }
  });

  test('les classes « saines » mènent à des fiches saines', () {
    expect(catalog.findByModelLabel('Corn Healthy')!.type, DiseaseType.healthy);
    expect(catalog.findByModelLabel('Cassava Healthy')!.type, DiseaseType.healthy);
    expect(catalog.findByModelLabel('Tomato healthy')!.type, DiseaseType.healthy);
    expect(catalog.findByModelLabel('Tomato blight leaf')!.id, 'tomato-late-blight');
  });

  test('base enrichie : au moins 55 fiches, toutes en français et en anglais', () {
    expect(catalog.diseases.length, greaterThanOrEqualTo(55));
    for (final d in catalog.diseases) {
      expect(d.name.values['fr'], isNotEmpty, reason: d.id);
      expect(d.name.values['en'], isNotEmpty, reason: d.id);
      for (final c in d.crops) {
        expect(catalog.crops.containsKey(c), isTrue, reason: '${d.id} → $c');
      }
      if (!d.isHealthy) {
        expect(d.symptoms.of('fr'), isNotEmpty, reason: d.id);
        expect(d.actions.of('en'), isNotEmpty, reason: d.id);
        expect(d.actions.of('fr').length, d.actions.of('en').length, reason: d.id);
      }
    }
  });

  test('« détectable par scan » ne concerne que les classes du modèle actif', () {
    final c = loadCatalog();
    final active = File('assets/models/tflite/labels.txt').readAsLinesSync().where((l) => l.trim().isNotEmpty).toList();
    c.setActiveModelLabels(active);
    expect(c.isDetectable(c.findById('cassava-brown-leaf-spot')!), isTrue);
    expect(c.isDetectable(c.findById('tomato-late-blight')!), isTrue);
    // Classe de l'ancien modèle ONNX, absente du TFLite.
    expect(c.isDetectable(c.findById('maize-streak-virus')!), isFalse);
    expect(c.diseases.where(c.isDetectable).length, 9);
  });

  test('identifiants uniques', () {
    final ids = catalog.diseases.map((d) => d.id).toList();
    expect(ids.toSet().length, ids.length);
  });

  test('recherche insensible aux accents, avec filtre par culture', () {
    expect(catalog.search('striure mais', locale: 'fr').map((d) => d.id), contains('maize-streak-virus'));
    final cassava = catalog.search('', locale: 'fr', cropId: 'cassava');
    expect(cassava.every((d) => d.crops.contains('cassava')), isTrue);
    expect(catalog.search('late blight', locale: 'en').map((d) => d.id), contains('tomato-late-blight'));
  });

  test('le pidgin et les langues inconnues retombent sur l\'anglais', () {
    final d = catalog.findById('fall-armyworm')!;
    expect(d.name.of('pid'), d.name.of('en'));
  });
}
