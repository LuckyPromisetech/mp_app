class Product {
  final String id;
  final String title;
  final String description;
  final double price;
  final String imageUrl; // Backward compatibility
  final List<String> images; // Multiple images support
  final double weight; // Product weight in kg
  final String sellerId;
  final String sellerstate; // NEW: seller state
  final String category;
  final String categoryId; // optional
  final int quantity;
  final int? discount; // <-- keep this

  Product({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.sellerstate,
    this.images = const [],
    this.weight = 1.0, // default 1kg
    required this.sellerId,
    required this.category,
    this.categoryId = '',
    this.quantity = 1,
    this.discount,
  });

  /// 🔥 New getter for promotion check
  bool get isPromoted => discount != null && discount! > 0;

  /// Create Product from Firestore
  factory Product.fromFirestore(Map<String, dynamic> data, String documentId) {
    List<String> imageList = [];
    if (data['images'] != null && data['images'] is List) {
      imageList = List<String>.from(data['images']);
    } else if (data['imageUrl'] != null && data['imageUrl'] is String) {
      imageList = [data['imageUrl']];
    }

    return Product(
      id: documentId,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      imageUrl: data['imageUrl'] ?? '',
      images: imageList,
      weight: (data['weight'] ?? 1.0).toDouble(),
      sellerId: data['sellerId'] ?? '',
      sellerstate: data['sellerstate'] ?? '', // NEW
      category: data['category'] ?? '',
      categoryId: data['categoryId'] ?? '',
      quantity: data['quantity'] ?? 1,
      discount: data['discount'] != null
          ? (data['discount'] as num).toInt()
          : null, // handle discount
    );
  }

  /// Create Product from Map (legacy)
  factory Product.fromMap(Map<String, dynamic> data) {
    List<String> imageList = [];
    if (data['images'] != null && data['images'] is List) {
      imageList = List<String>.from(data['images']);
    } else if (data['imageUrl'] != null && data['imageUrl'] is String) {
      imageList = [data['imageUrl']];
    }

    return Product(
      id: data['id'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      imageUrl: data['imageUrl'] ?? '',
      images: imageList,
      weight: (data['weight'] ?? 1.0).toDouble(),
      sellerId: data['sellerId'] ?? '',
      sellerstate: data['sellerstate'] ?? '', // NEW
      category: data['category'] ?? '',
      categoryId: data['categoryId'] ?? '',
      quantity: data['quantity'] ?? 1,
      discount: data['discount'] != null
          ? (data['discount'] as num).toInt()
          : null, // handle discount
    );
  }

  /// Convert Product to Map (for Firestore)
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'price': price,
      'imageUrl': imageUrl,
      'images': images,
      'weight': weight,
      'sellerId': sellerId,
      'sellerstate': sellerstate, // NEW
      'category': category,
      'categoryId': categoryId,
      'quantity': quantity,
      'discount': discount,
    };
  }

  /// CopyWith method
  Product copyWith({
    String? id,
    String? title,
    String? description,
    double? price,
    String? imageUrl,
    List<String>? images,
    double? weight,
    String? sellerId,
    String? sellerstate,
    String? category,
    String? categoryId,
    int? quantity,
    int? discount, // add to copyWith
  }) {
    return Product(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      images: images ?? this.images,
      weight: weight ?? this.weight,
      sellerId: sellerId ?? this.sellerId,
      sellerstate: sellerstate ?? this.sellerstate,
      category: category ?? this.category,
      categoryId: categoryId ?? this.categoryId,
      quantity: quantity ?? this.quantity,
      discount: discount ?? this.discount,
    );
  }
}
