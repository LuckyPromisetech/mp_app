import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as flutter_provider;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/products_model.dart';
import '../provider/cart_provider.dart';
import 'order_summary_screen.dart';
import 'product_detail_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({Key? key}) : super(key: key);

  Future<void> createOrder(BuildContext context) async {
    final cart = flutter_provider.Provider.of<CartProvider>(
      context,
      listen: false,
    );
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    final firestore = FirebaseFirestore.instance;

    try {
      // 1️⃣ Create order document
      final orderRef = await firestore.collection('orders').add({
        'buyer_id': user.uid,
        'total_price': cart.totalPrice,
        'created_at': FieldValue.serverTimestamp(),
      });

      // 2️⃣ Add order items subcollection
      final batch = firestore.batch();
      for (var product in cart.items) {
        final itemRef = orderRef.collection('order_items').doc();
        batch.set(itemRef, {
          'product_id': product.id,
          'title': product.title,
          'price': product.price,
          'quantity': product.quantity,
          'image_url': product.imageUrl,
        });
      }
      await batch.commit();

      // 3️⃣ Clear cart
      cart.clearCart();

      // 4️⃣ Navigate to summary screen
      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const OrderSummaryScreen()),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error creating order: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = flutter_provider.Provider.of<CartProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Your Cart')),
      body: cart.items.isEmpty
          ? const Center(
              child: Text('Your cart is empty', style: TextStyle(fontSize: 18)),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: cart.items.length,
                    itemBuilder: (context, index) {
                      final product = cart.items[index];

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        child: ListTile(
                          leading: Image.network(
                            product.imageUrl,
                            width: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                                  width: 50,
                                  color: Colors.grey.shade300,
                                  child: const Icon(Icons.image_not_supported),
                                ),
                          ),
                          title: Text(product.title),
                          subtitle: Text(
                            '₦${product.price.toStringAsFixed(0)}',
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              cart.removeFromCart(product);
                            },
                          ),
                          onTap: () {
                            // Go back to Product Detail
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    ProductDetailScreen(product: product),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total:',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '₦${cart.totalPrice.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 18,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => createOrder(context),
                          child: const Text('Place Order'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
