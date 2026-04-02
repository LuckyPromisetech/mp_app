import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class SellerOrderScreen extends StatelessWidget {
  const SellerOrderScreen({Key? key}) : super(key: key);

  static const Color orange = Colors.orange;
  static const Color navy = Color(0xFF0A1D37);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text("Seller not logged in")));
    }

    return Scaffold(
      backgroundColor: orange,
      appBar: AppBar(
        backgroundColor: navy,
        title: const Text("Seller Orders", style: TextStyle(color: orange)),
        iconTheme: const IconThemeData(color: orange),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('sellerId', isEqualTo: user.uid)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No orders yet"));
          }

          final orders = snapshot.data!.docs;

          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final orderDoc = orders[index];
              final data = orderDoc.data() as Map<String, dynamic>;

              final items = data['items'] ?? [];
              final total = (data['totalPrice'] ?? 0).toDouble();
              final paidNow = (data['paidNow'] ?? 0).toDouble();
              final remaining = (data['payOnDelivery'] ?? 0).toDouble();

              /// CUSTOMER INFO
              final name = data['buyerName'] ?? data['name'] ?? "No Name";
              final phone = data['buyerPhone'] ?? data['phone'] ?? "No Phone";
              final address = data['address'] ?? "No Address";
              final status = data['status'] ?? "pending";

              return Container(
                margin: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: navy,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: ExpansionTile(
                  collapsedIconColor: orange,
                  iconColor: orange,
                  title: Text(
                    "Order #${orderDoc.id.substring(0, 6)}",
                    style: const TextStyle(color: orange),
                  ),
                  subtitle: Text(
                    "Status: $status",
                    style: const TextStyle(color: Colors.white),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          /// CUSTOMER INFO
                          Text(
                            "Name: $name",
                            style: const TextStyle(color: Colors.white),
                          ),
                          Text(
                            "Phone: $phone",
                            style: const TextStyle(color: Colors.white),
                          ),
                          Text(
                            "Address: $address",
                            style: const TextStyle(color: Colors.white),
                          ),
                          const SizedBox(height: 10),

                          /// ITEMS
                          const Text(
                            "Items:",
                            style: TextStyle(
                              color: orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
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

                          const SizedBox(height: 10),

                          /// PAYMENT
                          Text(
                            "Total: ₦${total.toStringAsFixed(0)}",
                            style: const TextStyle(color: Colors.white),
                          ),
                          Text(
                            "Paid: ₦${paidNow.toStringAsFixed(0)}",
                            style: const TextStyle(color: Colors.green),
                          ),
                          if (remaining > 0)
                            Text(
                              "Remaining: ₦${remaining.toStringAsFixed(0)}",
                              style: const TextStyle(color: Colors.red),
                            ),
                          const SizedBox(height: 15),

                          /// PRINT RECEIPT
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: orange,
                            ),
                            onPressed: () => _printReceipt(data),
                            child: const Text("Print Receipt"),
                          ),
                          const SizedBox(height: 10),

                          /// DENY ORDER WITH REASON
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                            onPressed: () {
                              _showDenyReasonDialog(context, orderDoc.id);
                            },
                            child: const Text("Deny Order"),
                          ),
                          const SizedBox(height: 10),

                          /// CONFIRM
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                            ),
                            onPressed: () {
                              FirebaseFirestore.instance
                                  .collection('orders')
                                  .doc(orderDoc.id)
                                  .update({'status': 'confirmed'});
                            },
                            child: const Text("Confirm Order"),
                          ),
                          const SizedBox(height: 10),

                          /// SHIPPED
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                            ),
                            onPressed: () {
                              FirebaseFirestore.instance
                                  .collection('orders')
                                  .doc(orderDoc.id)
                                  .update({'status': 'shipped'});
                            },
                            child: const Text("Mark as Shipped"),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  /// SHOW DENY REASON INPUT
  void _showDenyReasonDialog(BuildContext context, String orderId) {
    final TextEditingController reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text("Reason for Denying Order"),
          content: TextField(
            controller: reasonController,
            decoration: const InputDecoration(hintText: "Enter reason..."),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                final reason = reasonController.text.trim();
                if (reason.isEmpty) return;

                FirebaseFirestore.instance
                    .collection('orders')
                    .doc(orderId)
                    .update({'status': 'cancelled', 'cancelReason': reason});

                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text("Order Denied ❌")));
              },
              child: const Text("Submit"),
            ),
          ],
        );
      },
    );
  }

  /// PRINT RECEIPT
  Future<void> _printReceipt(Map<String, dynamic> data) async {
    final pdf = pw.Document();
    final items = data['items'] ?? [];

    pdf.addPage(
      pw.Page(
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                "MP Marketplace Receipt",
                style: pw.TextStyle(fontSize: 20),
              ),
              pw.SizedBox(height: 10),
              pw.Text("Name: ${data['buyerName'] ?? data['name']}"),
              pw.Text("Phone: ${data['buyerPhone'] ?? data['phone']}"),
              pw.Text("Address: ${data['address']}"),
              pw.SizedBox(height: 10),
              pw.Text("Items:"),
              ...items.map((item) {
                final title = item['title'] ?? '';
                final qty = item['quantity'] ?? 1;
                final price = (item['price'] ?? 0).toDouble();
                return pw.Text(
                  "$title x$qty - ₦${(price * qty).toStringAsFixed(0)}",
                );
              }).toList(),
              pw.SizedBox(height: 10),
              pw.Text("Total: ₦${data['totalPrice']}"),
              pw.Text("Paid: ₦${data['paidNow']}"),
              pw.Text("Remaining: ₦${data['payOnDelivery']}"),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }
}
