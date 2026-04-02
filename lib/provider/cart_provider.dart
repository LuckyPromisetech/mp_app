import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/products_model.dart';

class CartItem {
  final Product product;
  final int quantity;
  final double deliveryPrice;
  final double discount; // ✅ add discount

  CartItem({
    required this.product,
    required this.quantity,
    required this.deliveryPrice,
    this.discount = 0, // default 0
  });

  Map<String, dynamic> toMap() {
    return {
      'productId': product.id,
      'title': product.title,
      'description': product.description,
      'price': product.price,
      'discount': discount, // save discount
      'imageUrl': product.imageUrl,
      'images': product.images,
      'weight': product.weight,
      'sellerId': product.sellerId,
      'sellerstate': product.sellerstate,
      'category': product.category,
      'categoryId': product.categoryId,
      'quantity': quantity,
      'deliveryPrice': deliveryPrice,
    };
  }

  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      product: Product(
        id: map['productId'] ?? '',
        title: map['title'] ?? '',
        description: map['description'] ?? '',
        price: (map['price'] ?? 0).toDouble(),
        discount: (map['discount'] ?? 0).toDouble(), // load discount
        imageUrl: map['imageUrl'] ?? '',
        images: map['images'] != null ? List<String>.from(map['images']) : [],
        weight: (map['weight'] ?? 1.0).toDouble(),
        sellerId: map['sellerId'] ?? '',
        sellerstate: map['sellerstate'] ?? '',
        category: map['category'] ?? '',
        categoryId: map['categoryId'] ?? '',
        quantity: map['quantity'] ?? 1,
      ),
      quantity: map['quantity'] ?? 1,
      deliveryPrice: (map['deliveryPrice'] ?? 0).toDouble(),
      discount: (map['discount'] ?? 0).toDouble(), // load discount
    );
  }
}

class CartProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<CartItem> _items = [];
  List<CartItem> get items => _items;

  /// 🔥 TOTAL PRICE WITH DISCOUNT
  double get totalPrice => _items.fold(0, (sum, item) {
    final discountedPrice = item.product.price * (1 - item.discount / 100);
    return sum +
        (discountedPrice * item.quantity) +
        (item.deliveryPrice * item.quantity);
  });

  int get itemCount => _items.length;

  /// ✅ ADD TO CART (NOW SAVES)
  void addToCart(
    Product product,
    int quantity,
    double deliveryPrice,
    String userId,
  ) {
    final index = _items.indexWhere((item) => item.product.id == product.id);

    if (index != -1) {
      final existing = _items[index];
      _items[index] = CartItem(
        product: existing.product,
        quantity: existing.quantity + quantity,
        deliveryPrice: deliveryPrice,
        discount: existing.discount,
      );
    } else {
      _items.add(
        CartItem(
          product: product,
          quantity: quantity,
          deliveryPrice: deliveryPrice,
          discount: (product.discount ?? 0)
              .toDouble(), // save discount from product
        ),
      );
    }

    notifyListeners();
    saveCartToFirestore(userId);
  }

  /// ❌ REMOVE (NOW SAVES)
  void removeFromCart(String productId, String userId) {
    _items.removeWhere((item) => item.product.id == productId);
    notifyListeners();
    saveCartToFirestore(userId);
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }

  /// ➕ INCREASE (NOW SAVES)
  void increaseQuantity(String productId, String userId) {
    final index = _items.indexWhere((item) => item.product.id == productId);

    if (index != -1) {
      final item = _items[index];
      _items[index] = CartItem(
        product: item.product,
        quantity: item.quantity + 1,
        deliveryPrice: item.deliveryPrice,
        discount: item.discount,
      );
      notifyListeners();
      saveCartToFirestore(userId);
    }
  }

  /// ➖ DECREASE (NOW SAVES)
  void decreaseQuantity(String productId, String userId) {
    final index = _items.indexWhere((item) => item.product.id == productId);

    if (index != -1 && _items[index].quantity > 1) {
      final item = _items[index];
      _items[index] = CartItem(
        product: item.product,
        quantity: item.quantity - 1,
        deliveryPrice: item.deliveryPrice,
        discount: item.discount,
      );
      notifyListeners();
      saveCartToFirestore(userId);
    }
  }

  /// --------------------- WATCHLIST ---------------------
  List<Product> _watchlist = [];
  List<Product> get watchlist => _watchlist;

  void setWatchlist(List<Product> products) {
    _watchlist = products;
    notifyListeners();
  }

  void addToWatchlist(Product product) {
    if (!_watchlist.any((p) => p.id == product.id)) {
      _watchlist.add(product);
      notifyListeners();
    }
  }

  void removeFromWatchlist(Product product) {
    _watchlist.removeWhere((p) => p.id == product.id);
    notifyListeners();
  }

  /// --------------------- FIRESTORE ---------------------
  Future<void> saveCartToFirestore(String userId) async {
    final cartData = _items.map((item) => item.toMap()).toList();
    await _firestore.collection('cart').doc(userId).set({
      'items': cartData,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> loadCartFromFirestore(String userId) async {
    final doc = await _firestore.collection('cart').doc(userId).get();

    if (doc.exists && doc.data()?['items'] != null) {
      final data = List<Map<String, dynamic>>.from(doc.data()!['items']);
      _items = data.map((item) => CartItem.fromMap(item)).toList();
      notifyListeners();
    }
  }

  Future<void> clearCartFromFirestore(String userId) async {
    await _firestore.collection('cart').doc(userId).delete();
    clearCart();
  }
}
