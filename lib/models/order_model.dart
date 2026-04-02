class OrderModel {
  final String id;
  final String userId;
  final List items;
  final double totalPrice;
  final String address;
  final String status;
  final DateTime createdAt;

  OrderModel({
    required this.id,
    required this.userId,
    required this.items,
    required this.totalPrice,
    required this.address,
    required this.status,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "userId": userId,
      "items": items,
      "totalPrice": totalPrice,
      "address": address,
      "status": status,
      "createdAt": createdAt.toIso8601String(),
    };
  }
}
