class Product {
  final String id;
  final String title;
  final String description;
  final double price;
  final String imageUrl;
  final double deliveryPrice;
  final String sellerId;
  final String category;
  int quantity;

  Product({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.deliveryPrice,
    required this.sellerId,
    required this.category,
    required this.quantity,
  });

  factory Product.fromFirestore(Map<String, dynamic> data, String documentId) {
    return Product(
      id: documentId,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      imageUrl: data['image_url'] ?? '',
      deliveryPrice: (data['delivery_price'] ?? 0).toDouble(),
      sellerId: data['seller_id'] ?? '',
      category: data['category'] ?? '',
      quantity: data['quantity'] ?? 0,
    );
  }
}
