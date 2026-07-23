import 'package:flutter_test/flutter_test.dart';
import 'package:green_app/models/disease_catalog_model.dart';

void main() {
  group('DiseaseCatalogModel', () {
    test('fromJson parses all fields', () {
      final json = {
        'id': 'd1',
        'name': 'Mildiou',
        'scientificName': 'Phytophthora infestans',
        'affectedPlants': ['Tomate', 'Pomme de terre'],
        'symptoms': ['Taches brunes'],
        'actions': ['Appliquer un fongicide'],
        'aliases': ['late blight'],
      };
      final d = DiseaseCatalogModel.fromJson(json);
      expect(d.id, 'd1');
      expect(d.name, 'Mildiou');
      expect(d.scientificName, 'Phytophthora infestans');
      expect(d.affectedPlants, ['Tomate', 'Pomme de terre']);
      expect(d.symptoms, ['Taches brunes']);
      expect(d.actions, ['Appliquer un fongicide']);
      expect(d.aliases, ['late blight']);
    });

    test('fromJson uses defensive fallbacks for missing fields', () {
      final d = DiseaseCatalogModel.fromJson({});
      expect(d.id, '');
      expect(d.name, '');
      expect(d.scientificName, '');
      expect(d.affectedPlants, isEmpty);
      expect(d.symptoms, isEmpty);
      expect(d.actions, isEmpty);
      expect(d.aliases, isEmpty);
    });

    test('fromJson coerces non-string list elements to strings', () {
      final d = DiseaseCatalogModel.fromJson({
        'id': 'd2',
        'symptoms': [1, true, 'texte'],
      });
      expect(d.symptoms, ['1', 'true', 'texte']);
    });

    test('toJson round-trips through fromJson', () {
      final original = DiseaseCatalogModel.fromJson({
        'id': 'd1',
        'name': 'Mildiou',
        'scientificName': 'Phytophthora infestans',
        'affectedPlants': ['Tomate'],
        'symptoms': ['Taches'],
        'actions': ['Traiter'],
        'aliases': ['blight'],
      });
      final restored = DiseaseCatalogModel.fromJson(original.toJson());
      expect(restored.toJson(), original.toJson());
    });
  });
}
