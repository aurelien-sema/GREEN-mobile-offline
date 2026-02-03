class OrderModel {
  final String id;
  final String productId;
  final String productName;
  final int quantity;
  final double price;
  final double totalPrice;
  final DateTime orderedAt;
  final String status; // pending, confirmed, shipped, delivered

  OrderModel({
    required this.id,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.price,
    required this.totalPrice,
    required this.orderedAt,
    this.status = 'pending',
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] as String,
      productId: json['productId'] as String,
      productName: json['productName'] as String,
      quantity: json['quantity'] as int,
      price: (json['price'] as num).toDouble(),
      totalPrice: (json['totalPrice'] as num).toDouble(),
      orderedAt: DateTime.parse(json['orderedAt'] as String),
      status: json['status'] as String? ?? 'pending',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'productId': productId,
        'productName': productName,
        'quantity': quantity,
        'price': price,
        'totalPrice': totalPrice,
        'orderedAt': orderedAt.toIso8601String(),
        'status': status,
      };
}
