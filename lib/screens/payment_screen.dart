import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/cart_provider.dart';

class PaymentScreen extends StatelessWidget {
  final String deliveryAddress;

  const PaymentScreen({Key? key, required this.deliveryAddress})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(title: const Text('Payment')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Total: ₦${cart.totalPrice.toStringAsFixed(0)}',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Delivery Address:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(deliveryAddress, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                // Simulate payment success
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Payment successful! Your order has been placed.',
                    ),
                  ),
                );

                // Clear the cart
                cart.clearCart();

                // Navigate back to home
                Navigator.popUntil(context, (route) => route.isFirst);
              },
              child: const Text('Pay Now'),
            ),
          ],
        ),
      ),
    );
  }
}
