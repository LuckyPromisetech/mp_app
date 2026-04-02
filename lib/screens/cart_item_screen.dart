import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/products_model.dart';
import '../provider/cart_provider.dart';

class CartItemScreen extends StatefulWidget {
  final CartItem cartItem;

  const CartItemScreen({Key? key, required this.cartItem}) : super(key: key);

  @override
  State<CartItemScreen> createState() => _CartItemScreenState();
}

class _CartItemScreenState extends State<CartItemScreen> {
  late String selectedState;
  final Color orange = const Color(0xFFFF8C00);
  final Color navy = const Color(0xFF0A1D37);

  @override
  void initState() {
    super.initState();
    // Initialize selectedState from cart item
    selectedState = widget.cartItem.selectedState.isNotEmpty
        ? widget.cartItem.selectedState
        : '';
  }

  /// Dummy delivery calculation based on state, product weight & quantity
  double calculateDeliveryPrice(String state, Product product, int quantity) {
    // Example: delivery fee 500 for same state, 1000 for other states
    double baseFee = state == product.sellerstate ? 500 : 1000;
    return baseFee * quantity * product.weight;
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final product = widget.cartItem.product;
    final quantity = widget.cartItem.quantity;
    final deliveryPrice = calculateDeliveryPrice(
      selectedState,
      product,
      quantity,
    );

    return Scaffold(
      backgroundColor: orange,
      appBar: AppBar(
        backgroundColor: navy,
        iconTheme: IconThemeData(color: orange),
        title: const Text('Cart Item', style: TextStyle(color: Colors.orange)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // PRODUCT IMAGE & TITLE
            Card(
              color: navy,
              child: ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    product.images.isNotEmpty
                        ? product.images.first
                        : product.imageUrl,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 60,
                      height: 60,
                      color: Colors.grey,
                      child: const Icon(Icons.image),
                    ),
                  ),
                ),
                title: Text(
                  product.title,
                  style: const TextStyle(color: Colors.orange),
                ),
                subtitle: Text(
                  "₦${product.price.toStringAsFixed(0)}",
                  style: const TextStyle(color: Colors.white),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    cartProvider.removeFromCart(product);
                    Navigator.pop(context);
                  },
                ),
              ),
            ),

            const SizedBox(height: 20),

            // QUANTITY CONTROLS
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: () {
                    cartProvider.decreaseQuantity(product);
                  },
                  icon: const Icon(Icons.remove_circle),
                  color: orange,
                  iconSize: 30,
                ),
                Text(
                  quantity.toString(),
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                ),
                IconButton(
                  onPressed: () {
                    cartProvider.increaseQuantity(product);
                  }, flutter run -d 24117RN76G
                  icon: const Icon(Icons.add_circle),
                  color: orange,
                  iconSize: 30,
                ),
              ],
            ),

            const SizedBox(height: 20),

            // SELECT DELIVERY STATE
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: DropdownButtonFormField<String>(
                value: selectedState.isNotEmpty ? selectedState : null,
                decoration: const InputDecoration(
                  labelText: 'Select Delivery State',
                  border: OutlineInputBorder(),
                ),
                items: ['Lagos', 'Abuja', 'Enugu', 'Rivers', 'Kano']
                    .map(
                      (state) =>
                          DropdownMenuItem(value: state, child: Text(state)),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    selectedState = value!;
                    widget.cartItem.selectedState = selectedState;
                  });
                },
              ),
            ),

            const SizedBox(height: 20),

            // DELIVERY PRICE
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Delivery Price:",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                Text(
                  "₦${deliveryPrice.toStringAsFixed(0)}",
                  style: const TextStyle(color: Colors.orange, fontSize: 16),
                ),
              ],
            ),

            const SizedBox(height: 30),

            // BACK BUTTON
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: navy,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () {
                  cartProvider.saveCartToFirestore('USER_ID_HERE'); // optional
                  Navigator.pop(context);
                },
                child: const Text(
                  "Save & Back to Cart",
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

/// CartItem class to use with CartProvider
class CartItem {
  Product product;
  int quantity;
  String selectedState;

  CartItem({required this.product, this.quantity = 1, this.selectedState = ''});
}
