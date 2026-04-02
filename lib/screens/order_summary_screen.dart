import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/cart_provider.dart';
import 'payment_screen.dart';

class OrderSummaryScreen extends StatefulWidget {
  const OrderSummaryScreen({Key? key}) : super(key: key);

  @override
  State<OrderSummaryScreen> createState() => _OrderSummaryScreenState();
}

class _OrderSummaryScreenState extends State<OrderSummaryScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);

    double itemsCost = 0;
    double deliveryCost = 0;

    for (var item in cartProvider.items) {
      final discount = item.product.discount ?? 0;
      final effectivePrice =
          item.product.price * (1 - (discount.toDouble() / 100));

      itemsCost += effectivePrice * item.quantity;
      deliveryCost += item.deliveryPrice * item.quantity;
    }

    double totalPrice = itemsCost + deliveryCost;

    return Scaffold(
      backgroundColor: Colors.orange,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A1D37),
        iconTheme: const IconThemeData(color: Colors.orange),
        title: const Text(
          "Order Summary",
          style: TextStyle(color: Colors.orange),
        ),
      ),
      body: cartProvider.items.isEmpty
          ? const Center(child: Text('Your cart is empty'))
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  /// 🛒 PRODUCT LIST
                  Expanded(
                    child: ListView.builder(
                      itemCount: cartProvider.items.length,
                      itemBuilder: (context, index) {
                        final cartItem = cartProvider.items[index];
                        final product = cartItem.product;

                        String image = product.images.isNotEmpty
                            ? product.images.first
                            : product.imageUrl;

                        final discount = product.discount ?? 0;
                        final effectivePrice =
                            product.price * (1 - (discount.toDouble() / 100));

                        double itemDelivery =
                            cartItem.deliveryPrice * cartItem.quantity;

                        double itemTotal =
                            (effectivePrice * cartItem.quantity) + itemDelivery;

                        return Card(
                          color: const Color(0xFF0A1D37),
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Row(
                              children: [
                                /// IMAGE
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    image,
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            Container(
                                              width: 60,
                                              height: 60,
                                              color: Colors.grey,
                                              child: const Icon(Icons.image),
                                            ),
                                  ),
                                ),

                                const SizedBox(width: 10),

                                /// DETAILS
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        product.title,
                                        style: const TextStyle(
                                          color: Colors.orange,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),

                                      Text(
                                        "₦${effectivePrice.toStringAsFixed(0)}",
                                        style: const TextStyle(
                                          color: Colors.orange,
                                        ),
                                      ),
                                      const SizedBox(height: 4),

                                      Text(
                                        "Qty: ${cartItem.quantity}",
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 4),

                                      Text(
                                        "Delivery: ₦${itemDelivery.toStringAsFixed(0)}",
                                        style: const TextStyle(
                                          color: Colors.white70,
                                        ),
                                      ),
                                      const SizedBox(height: 4),

                                      Text(
                                        "Item Total: ₦${itemTotal.toStringAsFixed(0)}",
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  /// 📦 DELIVERY INFO
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        TextField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: "Full Name",
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: "Phone Number",
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _addressController,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: "Delivery Address",
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  /// 💰 TOTAL
                  Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Items:",
                            style: TextStyle(color: Colors.white),
                          ),
                          Text(
                            "₦${itemsCost.toStringAsFixed(0)}",
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Delivery:",
                            style: TextStyle(color: Colors.white),
                          ),
                          Text(
                            "₦${deliveryCost.toStringAsFixed(0)}",
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Total:",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "₦${totalPrice.toStringAsFixed(0)}",
                            style: const TextStyle(
                              color: Colors.orange,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  /// 🚀 PROCEED TO PAYMENT
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0A1D37),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: () {
                        if (_nameController.text.isEmpty ||
                            _phoneController.text.isEmpty ||
                            _addressController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Please fill all delivery info"),
                            ),
                          );
                          return;
                        }

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PaymentScreen(
                              deliveryAddress: _addressController.text,
                              totalAmount: totalPrice,

                              // ✅ PASS BUYER DETAILS
                              buyerName: _nameController.text,
                              buyerPhone: _phoneController.text,
                              buyerstate: _addressController
                                  .text, // using address as state for now
                            ),
                          ),
                        );
                      },
                      child: const Text(
                        "Proceed to Payment",
                        style: TextStyle(color: Colors.orange, fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
