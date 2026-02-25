import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart' as flutter_provider;

import '../models/products_model.dart';
import '../screens/product_detail_screen.dart';
import '../screens/seller_screen.dart';
import '../screens/cart_screen.dart';
import '../screens/order_screen.dart';
import '../provider/cart_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;

  List<Product> products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  // ✅ FETCH PRODUCTS FROM FIRESTORE
  Future<void> _fetchProducts() async {
    setState(() => _isLoading = true);
    try {
      final snapshot = await firestore.collection('products').get();
      final docs = snapshot.docs;

      setState(() {
        products = docs.map((doc) => Product.fromMap(doc.data())).toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Fetch error: $e');
      setState(() => _isLoading = false);
    }
  }

  // ✅ DUMMY SELLER FLOW
  Future<void> _openSellerFlow() async {
    // Dummy seller data for now
    final dummyUser = {'id': 'dummy-user-id', 'email': 'dummy@seller.com'};
    final dummySeller = {
      'shop_name': 'My Dummy Shop',
      'shop_details': 'This is a test shop',
    };

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SellerScreen(
          profileName: dummyUser['email']!,
          shopName: dummySeller['shop_name']!,
          shopDetails: dummySeller['shop_details']!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = flutter_provider.Provider.of<CartProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          // 🛒 CART BUTTON
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CartScreen()),
                  );
                },
              ),
              if (cart.items.isNotEmpty)
                Positioned(
                  right: 4,
                  top: 4,
                  child: CircleAvatar(
                    radius: 8,
                    backgroundColor: Colors.red,
                    child: Text(
                      cart.items.length.toString(),
                      style: const TextStyle(fontSize: 10, color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),

          // 📦 ORDERS BUTTON
          IconButton(
            icon: const Icon(Icons.receipt_long),
            tooltip: 'Orders',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const OrderScreen()),
              );
            },
          ),

          // 🏪 SELLER BUTTON (Dummy)
          IconButton(
            icon: const Icon(Icons.store),
            tooltip: 'Seller',
            onPressed: _openSellerFlow,
          ),
        ],
      ),

      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : products.isEmpty
          ? const Center(child: Text('No products found.'))
          : RefreshIndicator(
              onRefresh: _fetchProducts,
              child: GridView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: products.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.7,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemBuilder: (context, index) {
                  final product = products[index];

                  return Card(
                    elevation: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: product.imageUrl.isNotEmpty
                              ? Image.network(
                                  product.imageUrl,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(Icons.image);
                                  },
                                )
                              : const Icon(Icons.image),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(6),
                          child: Text(
                            product.title,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Text(
                            '₦${product.price}',
                            style: const TextStyle(color: Colors.green),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    ProductDetailScreen(product: product),
                              ),
                            );
                          },
                          child: const Text("View"),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
    );
  }
}
