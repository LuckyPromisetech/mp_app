import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SellerOrderScreen extends StatefulWidget {
  const SellerOrderScreen({Key? key}) : super(key: key);

  @override
  State<SellerOrderScreen> createState() => _SellerOrderScreenState();
}

class _SellerOrderScreenState extends State<SellerOrderScreen> {
  final SupabaseClient supabase = Supabase.instance.client;

  bool _isLoading = true;
  List<Map<String, dynamic>> _orders = [];

  @override
  void initState() {
    super.initState();
    fetchSellerOrders();
  }

  Future<void> fetchSellerOrders() async {
    setState(() => _isLoading = true);

    final user = supabase.auth.currentUser;
    if (user == null) {
      setState(() {
        _orders = [];
        _isLoading = false;
      });
      return;
    }

    try {
      final response = await supabase
          .from('orders')
          .select()
          .eq('seller_id', user.id)
          .order('created_at', ascending: false)
          .execute();

      if (response.status >= 400) {
        debugPrint('Error fetching seller orders: HTTP ${response.status}');
        setState(() {
          _orders = [];
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _orders = List<Map<String, dynamic>>.from(response.data as List);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Exception fetching seller orders: $e');
      setState(() {
        _orders = [];
        _isLoading = false;
      });
    }
  }

  Future<void> markAsShipped(String orderId) async {
    try {
      final response = await supabase
          .from('orders')
          .update({'status': 'shipped'})
          .eq('id', orderId)
          .execute();

      if (response.status >= 400) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating order: HTTP ${response.status}'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order marked as shipped')),
        );
        fetchSellerOrders();
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Exception: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Seller Orders')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _orders.isEmpty
          ? const Center(
              child: Text(
                'No orders received yet',
                style: TextStyle(fontSize: 18),
              ),
            )
          : ListView.builder(
              itemCount: _orders.length,
              itemBuilder: (context, index) {
                final order = _orders[index];
                final status = order['status'] ?? 'pending';
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue,
                      child: Text(
                        (order['product_title'] as String)[0].toUpperCase(),
                      ),
                    ),
                    title: Text(order['product_title'] as String),
                    subtitle: Text(
                      '₦${(order['price'] as num).toStringAsFixed(0)}',
                    ),
                    trailing: status == 'pending'
                        ? ElevatedButton(
                            onPressed: () {
                              markAsShipped(order['id'] as String);
                            },
                            child: const Text('Mark Shipped'),
                          )
                        : Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Shipped',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                  ),
                );
              },
            ),
    );
  }
}
