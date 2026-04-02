import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../provider/cart_provider.dart';
import 'order_summary_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({Key? key}) : super(key: key);

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final user = FirebaseAuth.instance.currentUser;
  bool _isLoading = false;

  final Color orange = const Color(0xFFFF8C00);
  final Color navy = const Color(0xFF0A1D37);

  @override
  void initState() {
    super.initState();
    if (user != null) {
      Provider.of<CartProvider>(
        context,
        listen: false,
      ).loadCartFromFirestore(user!.uid);
    }
  }

  void _goToOrderSummary() {
    final cart = Provider.of<CartProvider>(context, listen: false);
    if (cart.items.isEmpty) return;

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const OrderSummaryScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);

    // ----------------- TOTAL PRICE -----------------
    double totalPrice = cart.totalPrice;

    return Scaffold(
      backgroundColor: orange,
      appBar: AppBar(
        backgroundColor: navy,
        iconTheme: IconThemeData(color: orange),
        title: Text('Your Cart', style: TextStyle(color: orange)),
      ),
      body: cart.items.isEmpty
          ? const Center(
              child: Text(
                'Your cart is empty',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: cart.items.length,
                    itemBuilder: (context, index) {
                      final cartItem = cart.items[index];
                      final product = cartItem.product;

                      String image = product.images.isNotEmpty
                          ? product.images.first
                          : product.imageUrl;

                      final discount = cartItem.discount;
                      final effectivePrice =
                          product.price * (1 - discount / 100);
                      final itemDelivery =
                          cartItem.deliveryPrice * cartItem.quantity;
                      final itemTotal =
                          (effectivePrice * cartItem.quantity) + itemDelivery;

                      return Card(
                        color: navy,
                        margin: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Row(
                            children: [
                              // IMAGE
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  image,
                                  width: 70,
                                  height: 70,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                        width: 70,
                                        height: 70,
                                        color: Colors.grey.shade300,
                                        child: const Icon(Icons.image),
                                      ),
                                ),
                              ),
                              const SizedBox(width: 10),

                              // DETAILS
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      product.title,
                                      style: TextStyle(
                                        color: orange,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '₦${effectivePrice.toStringAsFixed(0)}',
                                      style: TextStyle(
                                        color: orange,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Delivery: ₦${itemDelivery.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Item Total: ₦${itemTotal.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),

                                    // QUANTITY CONTROLS
                                    Row(
                                      children: [
                                        IconButton(
                                          color: orange,
                                          icon: const Icon(Icons.remove_circle),
                                          onPressed: () {
                                            if (user != null) {
                                              cart.decreaseQuantity(
                                                product.id,
                                                user!.uid,
                                              );
                                            }
                                          },
                                        ),
                                        Text(
                                          cartItem.quantity.toString(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                          ),
                                        ),
                                        IconButton(
                                          color: orange,
                                          icon: const Icon(Icons.add_circle),
                                          onPressed: () {
                                            if (user != null) {
                                              cart.increaseQuantity(
                                                product.id,
                                                user!.uid,
                                              );
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              // DELETE BUTTON
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () {
                                  if (user != null) {
                                    cart.removeFromCart(product.id, user!.uid);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // TOTAL PRICE SECTION
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: orange,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total Price:',
                            style: TextStyle(
                              fontSize: 18,
                              color: navy,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '₦${totalPrice.toStringAsFixed(0)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: navy,
                          ),
                          onPressed: _isLoading ? null : _goToOrderSummary,
                          child: _isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : Text(
                                  'Place Order',
                                  style: TextStyle(
                                    color: orange,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
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
