import 'package:flutter_test/flutter_test.dart';
import 'package:green_app/models/product_model.dart';

void main() {
  group('ProductModel', () {
    Map<String, dynamic> fullJson() => {
          'id': 'p1',
          'name': 'Engrais Bio',
          'categoryId': 'c1',
          'description': 'Description longue',
          'shortDescription': 'Courte',
          'characteristics': ['bio', 'naturel'],
          'supplierName': 'AgriCorp',
          'location': 'Douala',
          'priceMin': 1000,
          'priceMax': 3000,
          'imageUrl': 'assets/images/p1.png',
          'tags': ['promo'],
          'rating': 4.5,
          'reviewCount': 12,
        };

    test('fromJson parses all fields', () {
      final p = ProductModel.fromJson(fullJson());
      expect(p.id, 'p1');
      expect(p.name, 'Engrais Bio');
      expect(p.categoryId, 'c1');
      expect(p.characteristics, ['bio', 'naturel']);
      expect(p.supplierName, 'AgriCorp');
      expect(p.priceMin, 1000.0);
      expect(p.priceMax, 3000.0);
      expect(p.tags, ['promo']);
      expect(p.rating, 4.5);
      expect(p.reviewCount, 12);
    });

    test('fromJson applies defaults for optional/missing fields', () {
      final json = fullJson()
        ..remove('tags')
        ..remove('rating')
        ..remove('reviewCount')
        ..remove('characteristics');
      final p = ProductModel.fromJson(json);
      expect(p.tags, isEmpty);
      expect(p.characteristics, isEmpty);
      expect(p.rating, 0.0);
      expect(p.reviewCount, 0);
    });

    test('fromJson accepts integer prices as doubles', () {
      final p = ProductModel.fromJson(fullJson()..['priceMin'] = 500);
      expect(p.priceMin, 500.0);
      expect(p.priceMin, isA<double>());
    });

    test('price getter returns the average of min and max', () {
      final p = ProductModel.fromJson(fullJson());
      expect(p.price, 2000.0);
    });

    test('priceRange getter formats without decimals and FCFA suffix', () {
      final p = ProductModel.fromJson(fullJson());
      expect(p.priceRange, '1000 - 3000 FCFA');
    });

    test('toJson round-trips through fromJson', () {
      final original = ProductModel.fromJson(fullJson());
      final restored = ProductModel.fromJson(original.toJson());
      expect(restored.toJson(), original.toJson());
    });

    test('defaultImage sentinel value is stable', () {
      expect(ProductModel.defaultImage, 'default');
    });
  });

  group('CategoryModel', () {
    test('fromJson / toJson round-trip', () {
      final json = {
        'id': 'cat1',
        'name': 'Semences',
        'icon': 'seed',
        'description': 'Graines et semences',
      };
      final c = CategoryModel.fromJson(json);
      expect(c.id, 'cat1');
      expect(c.name, 'Semences');
      expect(c.icon, 'seed');
      expect(c.description, 'Graines et semences');
      expect(c.toJson(), json);
    });
  });
}
