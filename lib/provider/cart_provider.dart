// lib/providers/cart_provider.dart
import 'package:flutter/material.dart';
import '../models/products_model.dart';
import '../models/order_model.dart';

// lib/providers/cart_provider.dart
class CartProvider extends ChangeNotifier {
  List<Product> _items = [];
  List<Order> _orders = [];

  List<Product> get items => _items;
  List<Order> get orders => _orders;

  double get totalPrice => _items.fold(0, (sum, item) => sum + item.price);

  // Add this getter for itemCount
  int get itemCount => _items.length;

  void addToCart(Product product) {
    _items.add(product);
    notifyListeners();
  }

  void removeFromCart(Product product) {
    _items.remove(product);
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }

  void placeOrder(String deliveryAddress) {
    for (var product in _items) {
      _orders.add(
        Order(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          productTitle: product.title,
          price: product.price,
          status: 'pending',
        ),
      );
    }
    clearCart();
    notifyListeners();
  }
}
