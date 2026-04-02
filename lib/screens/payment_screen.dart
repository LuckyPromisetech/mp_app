import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutterwave_standard/flutterwave.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:url_launcher/url_launcher.dart';

import '../provider/cart_provider.dart';

class PaymentScreen extends StatefulWidget {
  final String deliveryAddress;
  final String buyerstate;
  final double totalAmount;
  final String buyerName;
  final String buyerPhone;

  const PaymentScreen({
    Key? key,
    required this.deliveryAddress,
    required this.totalAmount,
    required this.buyerName,
    required this.buyerPhone,
    required this.buyerstate,
  }) : super(key: key);

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool _isLoading = false;
  String paymentType = "full";

  final String _publicKey = "FLWPUBK_TEST-d3d58cfbfa6f5934baa6f7ca9fb79b18-X";

  double getPayNowAmount(double items, double delivery) {
    return paymentType == "half" ? (items / 2) + delivery : items + delivery;
  }

  double getPayLaterAmount(double items) {
    return paymentType == "half" ? items / 2 : 0;
  }

  /// 🔗 NEW: Hosted Link Payment via Railway backend
  Future<void> payWithHostedLink(double amount) async {
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not logged in");

      String? backendUrl = dotenv.env['BACKEND_URL'];
      backendUrl ??= "https://edgebaz-production.up.railway.app";

      print("🌐 Backend URL: $backendUrl");

      final txRef = "TX_${DateTime.now().millisecondsSinceEpoch}";

      final response = await http.post(
        Uri.parse('$backendUrl/promote'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "amount": amount,
          "email": user.email ?? "user@example.com",
          "tx_ref": txRef,
          "phone": widget.buyerPhone,
          "buyerName": widget.buyerName,
        }),
      );

      final data = jsonDecode(response.body);

      if (data['status'] == 'success') {
        final link = data['data']['link'];
        print("🔥 Payment Link: $link");

        // Launch link in browser
        final uri = Uri.parse(link);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          throw Exception("Could not launch payment link");
        }
      } else {
        throw Exception(data['message'] ?? "Failed to create payment link ❌");
      }
    } catch (e) {
      print("❌ ERROR: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }

    setState(() => _isLoading = false);
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

    double payNow = getPayNowAmount(itemsCost, deliveryCost);
    double payLater = getPayLaterAmount(itemsCost);

    return Scaffold(
      backgroundColor: Colors.orange,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A1D37),
        iconTheme: const IconThemeData(color: Colors.orange),
        title: const Text("Payment", style: TextStyle(color: Colors.orange)),
      ),
      body: cartProvider.items.isEmpty
          ? const Center(child: Text("No items to pay for"))
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  /// 🛒 ITEMS
                  Expanded(
                    child: ListView.builder(
                      itemCount: cartProvider.items.length,
                      itemBuilder: (context, index) {
                        final item = cartProvider.items[index];

                        final discount = item.product.discount ?? 0;
                        final effectivePrice =
                            item.product.price *
                            (1 - (discount.toDouble() / 100));

                        return Card(
                          color: const Color(0xFF0A1D37),
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            leading: Image.network(
                              item.product.imageUrl,
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  const Icon(Icons.image),
                            ),
                            title: Text(
                              item.product.title,
                              style: const TextStyle(color: Colors.orange),
                            ),
                            subtitle: Text(
                              "Qty: ${item.quantity}",
                              style: const TextStyle(color: Colors.white),
                            ),
                            trailing: Text(
                              "₦${(effectivePrice * item.quantity).toStringAsFixed(0)}",
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 10),

                  /// 📦 ADDRESS + BUYER INFO
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Name: ${widget.buyerName}"),
                        Text("Phone: ${widget.buyerPhone}"),
                        const SizedBox(height: 6),
                        Text("Address:\n${widget.deliveryAddress}"),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  /// 💳 PAYMENT TYPE
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile(
                          value: "full",
                          groupValue: paymentType,
                          onChanged: (value) =>
                              setState(() => paymentType = value.toString()),
                          title: const Text(
                            "Full Payment",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                      Expanded(
                        child: RadioListTile(
                          value: "half",
                          groupValue: paymentType,
                          onChanged: (value) =>
                              setState(() => paymentType = value.toString()),
                          title: const Text(
                            "Half Payment",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),

                  /// 💰 BREAKDOWN
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Text("Pay Now: ₦${payNow.toStringAsFixed(0)}"),
                        if (paymentType == "half")
                          Text(
                            "Pay on Delivery: ₦${payLater.toStringAsFixed(0)}",
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  /// 💳 PAY BUTTON (Both Flutterwave & Hosted Link)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0A1D37),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: _isLoading
                          ? null
                          : () async {
                              // 🔥 Choose which payment to use
                              // Example: Uncomment one:
                              // await payWithHostedLink(payNow); // Railway backend
                              // OR keep original Flutterwave code below

                              setState(() => _isLoading = true);

                              try {
                                final user = FirebaseAuth.instance.currentUser;

                                if (user == null) {
                                  throw Exception("User not logged in");
                                }

                                // ORIGINAL FLUTTERWAVE PAYMENT
                                final Customer customer = Customer(
                                  name: widget.buyerName,
                                  email: user.email ?? "test@gmail.com",
                                  phoneNumber: widget.buyerPhone,
                                );

                                final Flutterwave flutterwave = Flutterwave(
                                  publicKey: _publicKey,
                                  currency: "NGN",
                                  txRef:
                                      "MP_${DateTime.now().millisecondsSinceEpoch}",
                                  amount: payNow.toStringAsFixed(2),
                                  customer: customer,
                                  paymentOptions: "card, ussd, banktransfer",
                                  customization: Customization(
                                    title: "EdgeBaz",
                                    description: "Order Payment",
                                  ),
                                  redirectUrl: "https://google.com",
                                  isTestMode: true,
                                );

                                final response = await flutterwave.charge(
                                  context,
                                );

                                if (response != null &&
                                    response.success == true) {
                                  await FirebaseFirestore.instance
                                      .collection("orders")
                                      .add({
                                        "buyerId": user.uid,
                                        "buyerName": widget.buyerName,
                                        "buyerPhone": widget.buyerPhone,
                                        "sellerId": cartProvider
                                            .items
                                            .first
                                            .product
                                            .sellerId,
                                        "items": cartProvider.items.map((e) {
                                          final discount =
                                              e.product.discount ?? 0;
                                          final effectivePrice =
                                              e.product.price *
                                              (1 - (discount.toDouble() / 100));

                                          return {
                                            "title": e.product.title,
                                            "price": effectivePrice,
                                            "quantity": e.quantity,
                                            "image": e.product.imageUrl,
                                          };
                                        }).toList(),
                                        "totalPrice": widget.totalAmount,
                                        "paidNow": payNow,
                                        "payOnDelivery": payLater,
                                        "paymentType": paymentType,
                                        "address": widget.deliveryAddress,
                                        "status": "pending",
                                        "createdAt":
                                            FieldValue.serverTimestamp(),
                                      });

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("Payment Successful 🎉"),
                                    ),
                                  );

                                  cartProvider.clearCart();

                                  Navigator.popUntil(
                                    context,
                                    (route) => route.isFirst,
                                  );
                                } else {
                                  throw Exception("Payment Failed");
                                }
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(e.toString())),
                                );
                              }

                              setState(() => _isLoading = false);
                            },
                      child: _isLoading
                          ? const CircularProgressIndicator(
                              color: Colors.orange,
                            )
                          : const Text(
                              "Pay Now",
                              style: TextStyle(
                                color: Colors.orange,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
