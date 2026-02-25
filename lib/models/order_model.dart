// lib/models/order_model.dart
class Order {
  final String id;
  final String productTitle;
  final double price;
  String status; // pending, shipped, completed

  Order({
    required this.id,
    required this.productTitle,
    required this.price,
    this.status = 'pending',
  });
}
