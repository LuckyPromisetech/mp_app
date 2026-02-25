import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../screens/add_product_screen.dart';

class SellerScreen extends StatefulWidget {
  final String profileName;
  final String shopName;
  final String shopDetails;

  const SellerScreen({
    Key? key,
    required this.profileName,
    required this.shopName,
    required this.shopDetails,
  }) : super(key: key);

  @override
  State<SellerScreen> createState() => _SellerHomeScreenState();
}

class _SellerHomeScreenState extends State<SellerScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<Map<String, dynamic>> sellerProducts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSellerProducts();
  }

  Future<void> _fetchSellerProducts() async {
    setState(() => _isLoading = true);

    final user = supabase.auth.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final response = await supabase
          .from('products')
          .select()
          .eq('seller_id', user.id)
          .order('created_at', ascending: false)
          .execute();

      if (response.status >= 400) {
        // New way to handle errors
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error fetching products: HTTP ${response.status}'),
          ),
        );
        setState(() => _isLoading = false);
        return;
      }

      setState(() {
        sellerProducts = List<Map<String, dynamic>>.from(response.data as List);
        for (var product in sellerProducts) {
          product['quantity'] = product['quantity'] ?? 0;
          product['image_url'] = product['image_url'] ?? '';
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Exception fetching products: $e')),
      );
    }
  }

  void _increaseQuantity(int index) {
    setState(() {
      sellerProducts[index]['quantity']++;
    });
  }

  void _decreaseQuantity(int index) {
    setState(() {
      if (sellerProducts[index]['quantity'] > 0) {
        sellerProducts[index]['quantity']--;
      }
    });
  }

  Future<void> _addProduct() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddProductScreen()),
    );

    if (result != null) {
      _fetchSellerProducts();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seller Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.list_alt),
            tooltip: 'Orders',
            onPressed: () {
              // Navigate to SellerOrderScreen
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addProduct,
        child: const Icon(Icons.add),
        tooltip: 'Add Product',
      ),
      body: Column(
        children: [
          Container(
            color: Colors.green.shade100,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundImage: const NetworkImage(
                    'https://via.placeholder.com/150',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.profileName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.shopName,
                        style: const TextStyle(fontSize: 16),
                      ),
                      Text(
                        widget.shopDetails,
                        style: const TextStyle(fontSize: 14),
                      ),
                      Row(
                        children: List.generate(
                          5,
                          (index) => const Icon(
                            Icons.star,
                            size: 16,
                            color: Colors.orange,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : sellerProducts.isEmpty
                ? const Center(child: Text('No products added yet.'))
                : GridView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: sellerProducts.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.7,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                    itemBuilder: (context, index) {
                      final product = sellerProducts[index];
                      return Card(
                        elevation: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            product['image_url'] != ''
                                ? Image.network(
                                    product['image_url'],
                                    height: 100,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            Container(
                                              height: 100,
                                              color: Colors.grey.shade300,
                                              child: const Icon(
                                                Icons.image_not_supported,
                                              ),
                                            ),
                                  )
                                : Container(
                                    height: 100,
                                    color: Colors.grey.shade300,
                                    child: const Icon(
                                      Icons.image_not_supported,
                                    ),
                                  ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                product['title'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              child: Text(
                                '₦${product['price'].toString()}',
                                style: const TextStyle(color: Colors.green),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove),
                                  onPressed: () => _decreaseQuantity(index),
                                ),
                                Text(product['quantity'].toString()),
                                IconButton(
                                  icon: const Icon(Icons.add),
                                  onPressed: () => _increaseQuantity(index),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
