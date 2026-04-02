import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminOrderScreen extends StatefulWidget {
  const AdminOrderScreen({Key? key}) : super(key: key);

  @override
  State<AdminOrderScreen> createState() => _AdminOrderScreenState();
}

class _AdminOrderScreenState extends State<AdminOrderScreen> {
  static const Color kOrange = Colors.orange;
  static const Color kNavy = Color(0xFF0A1D37);

  final TextEditingController _passwordController = TextEditingController();
  final String _adminPassword = "Ifeanyilucky454"; // 🔐 Set your password
  bool _isAuthenticated = false;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    // PASSWORD SCREEN
    if (!_isAuthenticated) {
      return Scaffold(
        backgroundColor: kOrange,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Admin Login",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: kNavy,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: "Enter Password",
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kNavy,
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 24,
                    ),
                  ),
                  onPressed: () {
                    if (_passwordController.text == _adminPassword) {
                      setState(() => _isAuthenticated = true);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Incorrect Password 🚫")),
                      );
                    }
                  },
                  child: const Text(
                    "Login",
                    style: TextStyle(color: kOrange, fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // NOT LOGGED IN
    if (user == null) {
      return const Scaffold(body: Center(child: Text("Not logged in")));
    }

    // ADMIN DASHBOARD
    return Scaffold(
      backgroundColor: kOrange,
      appBar: AppBar(
        backgroundColor: kNavy,
        title: const Text("Admin Dashboard", style: TextStyle(color: kOrange)),
        iconTheme: const IconThemeData(color: kOrange),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No orders found"));
          }

          final orders = snapshot.data!.docs;
          double totalRevenue = 0;
          for (var doc in orders) {
            final data = doc.data() as Map<String, dynamic>;
            totalRevenue += (data['totalPrice'] ?? 0).toDouble();
          }

          return Column(
            children: [
              // TOP STATS
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                color: kNavy,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Total Orders: ${orders.length}",
                      style: const TextStyle(color: Colors.white),
                    ),
                    Text(
                      "Total Revenue: ₦${totalRevenue.toStringAsFixed(0)}",
                      style: const TextStyle(
                        color: kOrange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // ORDER LIST
              Expanded(
                child: ListView.builder(
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final orderDoc = orders[index];
                    final order =
                        orderDoc.data() as Map<String, dynamic>? ?? {};

                    final items = order['items'] ?? [];
                    final status = order['status'] ?? 'pending';
                    final address = order['address'] ?? '';
                    final cancelReason = order['cancelReason'] ?? '';
                    final returnRequested = order['returnRequested'] ?? false;

                    return Container(
                      margin: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: kNavy,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: ExpansionTile(
                        iconColor: kOrange,
                        collapsedIconColor: kOrange,
                        title: Text(
                          "Order #${orderDoc.id.substring(0, 6)}",
                          style: const TextStyle(color: kOrange),
                        ),
                        subtitle: Text(
                          "Status: $status",
                          style: const TextStyle(color: Colors.white),
                        ),
                        children: [
                          ...items.map<Widget>((item) {
                            final title = item['title'] ?? '';
                            final qty = item['quantity'] ?? 1;
                            final price = (item['price'] ?? 0).toDouble();

                            return ListTile(
                              title: Text(
                                title,
                                style: const TextStyle(color: Colors.white),
                              ),
                              subtitle: Text(
                                "Qty: $qty",
                                style: const TextStyle(color: Colors.white70),
                              ),
                              trailing: Text(
                                "₦${(price * qty).toStringAsFixed(0)}",
                                style: const TextStyle(color: Colors.white),
                              ),
                            );
                          }).toList(),

                          Padding(
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Address: $address",
                                  style: const TextStyle(color: Colors.white),
                                ),
                                if (cancelReason.isNotEmpty)
                                  Text(
                                    "Seller Cancel Reason: $cancelReason",
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                const SizedBox(height: 10),

                                if (returnRequested)
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green,
                                          ),
                                          onPressed: () {
                                            FirebaseFirestore.instance
                                                .collection('orders')
                                                .doc(orderDoc.id)
                                                .update({
                                                  'status': 'return_approved',
                                                });
                                          },
                                          child: const Text("Approve Return"),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red,
                                          ),
                                          onPressed: () {
                                            FirebaseFirestore.instance
                                                .collection('orders')
                                                .doc(orderDoc.id)
                                                .update({
                                                  'returnRequested': false,
                                                  'status': 'completed',
                                                });
                                          },
                                          child: const Text("Reject Return"),
                                        ),
                                      ),
                                    ],
                                  ),

                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 10,
                                  children: [
                                    _btn("Confirm", Colors.green, () {
                                      FirebaseFirestore.instance
                                          .collection('orders')
                                          .doc(orderDoc.id)
                                          .update({'status': 'confirmed'});
                                    }),
                                    _btn("Ship", Colors.blue, () {
                                      FirebaseFirestore.instance
                                          .collection('orders')
                                          .doc(orderDoc.id)
                                          .update({'status': 'shipped'});
                                    }),
                                    _btn("Complete", Colors.orange, () {
                                      FirebaseFirestore.instance
                                          .collection('orders')
                                          .doc(orderDoc.id)
                                          .update({'status': 'completed'});
                                    }),
                                    _btn("Cancel", Colors.red, () {
                                      FirebaseFirestore.instance
                                          .collection('orders')
                                          .doc(orderDoc.id)
                                          .update({'status': 'cancelled'});
                                    }),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _btn(String text, Color color, VoidCallback onTap) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(backgroundColor: color),
      onPressed: onTap,
      child: Text(text),
    );
  }
}
