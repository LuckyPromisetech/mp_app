import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OrderScreen extends StatefulWidget {
  const OrderScreen({Key? key}) : super(key: key);

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;

  bool _isLoading = true;
  List<Map<String, dynamic>> _orders = [];

  @override
  void initState() {
    super.initState();
    fetchOrders();
  }

  Future<void> fetchOrders() async {
    setState(() => _isLoading = true);

    final user = auth.currentUser;
    if (user == null) {
      setState(() {
        _orders = [];
        _isLoading = false;
      });
      return;
    }

    try {
      // Fetch buyer's orders
      final orderSnapshots = await firestore
          .collection('orders')
          .where('buyer_id', isEqualTo: user.uid)
          .orderBy('created_at', descending: true)
          .get();

      List<Map<String, dynamic>> buyerOrders = [];

      for (var orderDoc in orderSnapshots.docs) {
        final orderData = orderDoc.data();
        final itemsSnapshot = await firestore
            .collection('orders')
            .doc(orderDoc.id)
            .collection('order_items')
            .get();

        buyerOrders.add({
          'order_id': orderDoc.id,
          'total_price': orderData['total_price'] ?? 0.0,
          'status': orderData['status'] ?? 'pending',
          'items': itemsSnapshot.docs.map((doc) => doc.data()).toList(),
          'created_at': orderData['created_at'],
        });
      }

      setState(() {
        _orders = buyerOrders;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching buyer orders: $e');
      setState(() {
        _orders = [];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Orders')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _orders.isEmpty
          ? const Center(
              child: Text(
                'You have no orders yet',
                style: TextStyle(fontSize: 18),
              ),
            )
          : ListView.builder(
              itemCount: _orders.length,
              itemBuilder: (context, index) {
                final order = _orders[index];
                final status = order['status'] as String;
                final items = order['items'] as List<dynamic>;

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  child: ExpansionTile(
                    title: Text('Order #${order['order_id']}'),
                    subtitle: Text(
                      'Total: ₦${(order['total_price'] ?? 0).toStringAsFixed(0)}',
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: status == 'pending'
                            ? Colors.orange
                            : Colors.green,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    children: items.map((item) {
                      return ListTile(
                        leading: Image.network(
                          item['image_url'] ?? '',
                          width: 50,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.image_not_supported),
                        ),
                        title: Text(item['title'] ?? ''),
                        subtitle: Text('Quantity: ${item['quantity'] ?? 1}'),
                        trailing: Text(
                          '₦${(item['price'] ?? 0).toStringAsFixed(0)}',
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
    );
  }
}
