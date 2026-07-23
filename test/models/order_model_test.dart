import 'package:flutter_test/flutter_test.dart';
import 'package:green_app/models/order_model.dart';

void main() {
  group('OrderModel', () {
    test('constructor applies defaults', () {
      final o = OrderModel(
        id: 'o1',
        productId: 'p1',
        productName: 'Engrais',
        quantity: 2,
        price: 1500,
        totalPrice: 3000,
        orderedAt: DateTime(2026, 2, 3, 14, 30),
      );
      expect(o.status, 'pending');
      expect(o.paymentMethod, '');
      expect(o.deliveryMethod, '');
      expect(o.deliveryFee, 0);
    });

    test('fromJson parses all fields including a valid ISO date', () {
      final json = {
        'id': 'o1',
        'productId': 'p1',
        'productName': 'Engrais',
        'quantity': 3,
        'price': 1000,
        'totalPrice': 3500,
        'orderedAt': '2026-02-03T14:30:00.000',
        'status': 'shipped',
        'paymentMethod': 'mobile_money',
        'deliveryMethod': 'pickup',
        'deliveryFee': 500,
      };
      final o = OrderModel.fromJson(json);
      expect(o.quantity, 3);
      expect(o.price, 1000.0);
      expect(o.totalPrice, 3500.0);
      expect(o.orderedAt, DateTime.parse('2026-02-03T14:30:00.000'));
      expect(o.status, 'shipped');
      expect(o.paymentMethod, 'mobile_money');
      expect(o.deliveryMethod, 'pickup');
      expect(o.deliveryFee, 500.0);
    });

    test('fromJson falls back to defaults when optional fields missing', () {
      final json = {
        'id': 'o1',
        'productId': 'p1',
        'productName': 'Engrais',
        'quantity': 1,
        'price': 1000,
        'totalPrice': 1000,
        'orderedAt': '2026-02-03T14:30:00.000',
      };
      final o = OrderModel.fromJson(json);
      expect(o.status, 'pending');
      expect(o.paymentMethod, '');
      expect(o.deliveryMethod, '');
      expect(o.deliveryFee, 0);
    });

    test('toJson serializes orderedAt as ISO 8601 and round-trips', () {
      final o = OrderModel(
        id: 'o1',
        productId: 'p1',
        productName: 'Engrais',
        quantity: 2,
        price: 1500,
        totalPrice: 3000,
        orderedAt: DateTime(2026, 2, 3, 14, 30),
        status: 'confirmed',
        paymentMethod: 'cash',
        deliveryMethod: 'delivery',
        deliveryFee: 750,
      );
      final json = o.toJson();
      expect(json['orderedAt'], DateTime(2026, 2, 3, 14, 30).toIso8601String());
      final restored = OrderModel.fromJson(json);
      expect(restored.toJson(), json);
    });
  });
}
