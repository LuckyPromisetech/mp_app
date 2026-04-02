import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OrderScreen extends StatelessWidget {
  const OrderScreen({Key? key}) : super(key: key);

  static const Color kOrange = Colors.orange;
  static const Color kNavy = Color(0xFF0A1D37);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text("User not logged in")));
    }

    return Scaffold(
      backgroundColor: kOrange,
      appBar: AppBar(
        backgroundColor: kNavy,
        title: const Text("My Orders", style: TextStyle(color: kOrange)),
        iconTheme: const IconThemeData(color: kOrange),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // 🔑 Stream only for orders where buyerId matches
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('buyerId', isEqualTo: user.uid)
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
            return const Center(
              child: Text(
                "No orders yet",
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          // 🔹 Client-side filtering to avoid disappearing orders due to status
          final allOrders = snapshot.data!.docs;
          final orders = allOrders
              .map((doc) => doc.data() as Map<String, dynamic>)
              .toList();

          return ListView.builder(
            itemCount: allOrders.length,
            itemBuilder: (context, index) {
              final orderDoc = allOrders[index];
              final data = orderDoc.data() as Map<String, dynamic>;

              final items = data['items'] ?? [];
              final total = (data['totalPrice'] ?? 0).toDouble();
              final status = data['status'] ?? 'pending';
              final address = data['address'] ?? '';
              final cancelReason = data['cancelReason'] ?? '';
              final paidNow = (data['paidNow'] ?? 0).toDouble();
              final payLater = (data['payOnDelivery'] ?? 0).toDouble();
              final paymentType = data['paymentType'] ?? "full";
              final returnRequested = data['returnRequested'] ?? false;
              final sellerMessage = data['sellerMessage'] ?? '';

              Timestamp? timestamp = data['createdAt'];
              String dateText = timestamp != null
                  ? timestamp.toDate().toString()
                  : "Processing...";

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: kNavy,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ExpansionTile(
                  iconColor: kOrange,
                  collapsedIconColor: kOrange,
                  title: Text(
                    "Order #${orderDoc.id.substring(0, 6)}",
                    style: const TextStyle(color: kOrange),
                  ),
                  subtitle: Text(
                    "Status: ${status.toUpperCase()}",
                    style: const TextStyle(color: Colors.white70),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Date: $dateText",
                            style: const TextStyle(color: Colors.white),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            "Address: $address",
                            style: const TextStyle(color: Colors.white),
                          ),
                          if (cancelReason.isNotEmpty)
                            Text(
                              "Seller Response: $cancelReason",
                              style: const TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          if (sellerMessage.isNotEmpty)
                            Text(
                              "Seller Message: $sellerMessage",
                              style: const TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          const SizedBox(height: 10),

                          // 🔹 ITEMS
                          const Text(
                            "Items:",
                            style: TextStyle(
                              color: kOrange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          ...items.map<Widget>((item) {
                            final price = (item['price'] ?? 0).toDouble();
                            final qty = item['quantity'] ?? 1;
                            return ListTile(
                              title: Text(
                                item['title'] ?? '',
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

                          // 🔹 TOTAL
                          Text(
                            "Total: ₦${total.toStringAsFixed(0)}",
                            style: const TextStyle(
                              color: kOrange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),

                          // 🔹 HALF PAYMENT INFO
                          if (paymentType == "half" && payLater > 0)
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                "Remaining Payment: ₦${payLater.toStringAsFixed(0)}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          const SizedBox(height: 10),

                          // 🔹 ACTION BUTTONS
                          Row(
                            children: [
                              // MAIN BUTTON
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: kOrange,
                                  ),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (ctx) {
                                        final TextEditingController reviewCtrl =
                                            TextEditingController();
                                        return AlertDialog(
                                          title: const Text("Confirm Delivery"),
                                          content: TextField(
                                            controller: reviewCtrl,
                                            maxLines: 3,
                                            decoration: const InputDecoration(
                                              hintText: "Leave a review",
                                            ),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () {
                                                Navigator.of(ctx).pop();
                                              },
                                              child: const Text("Cancel"),
                                            ),
                                            ElevatedButton(
                                              onPressed: () async {
                                                await FirebaseFirestore.instance
                                                    .collection("orders")
                                                    .doc(orderDoc.id)
                                                    .update({
                                                      "status": "completed",
                                                      "buyerReview": reviewCtrl
                                                          .text
                                                          .trim(),
                                                    });
                                                Navigator.of(ctx).pop();
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      "Order marked as received ✅",
                                                    ),
                                                  ),
                                                );
                                              },
                                              child: const Text("Submit"),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                  child: Text(
                                    paymentType == "half" && payLater > 0
                                        ? "Pay Remaining"
                                        : "Item Received",
                                    style: const TextStyle(color: kNavy),
                                  ),
                                ),
                              ),

                              const SizedBox(width: 10),

                              // REQUEST RETURN BUTTON
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                  ),
                                  onPressed: returnRequested
                                      ? null
                                      : () {
                                          showDialog(
                                            context: context,
                                            builder: (ctx) {
                                              final TextEditingController
                                              reasonCtrl =
                                                  TextEditingController();
                                              return AlertDialog(
                                                title: const Text(
                                                  "Request Return",
                                                ),
                                                content: TextField(
                                                  controller: reasonCtrl,
                                                  maxLines: 3,
                                                  decoration:
                                                      const InputDecoration(
                                                        hintText:
                                                            "Reason for return",
                                                      ),
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () {
                                                      Navigator.of(ctx).pop();
                                                    },
                                                    child: const Text("Cancel"),
                                                  ),
                                                  ElevatedButton(
                                                    onPressed: () async {
                                                      await FirebaseFirestore
                                                          .instance
                                                          .collection("orders")
                                                          .doc(orderDoc.id)
                                                          .update({
                                                            "returnRequested":
                                                                true,
                                                            "returnReason":
                                                                reasonCtrl.text
                                                                    .trim(),
                                                            "status":
                                                                "return_requested",
                                                          });
                                                      Navigator.of(ctx).pop();
                                                      ScaffoldMessenger.of(
                                                        context,
                                                      ).showSnackBar(
                                                        const SnackBar(
                                                          content: Text(
                                                            "Return request sent",
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                    child: const Text("Send"),
                                                  ),
                                                ],
                                              );
                                            },
                                          );
                                        },
                                  child: Text(
                                    returnRequested
                                        ? "Return Requested"
                                        : "Request Return",
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
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
}
