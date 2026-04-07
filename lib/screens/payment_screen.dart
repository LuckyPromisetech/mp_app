import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../provider/cart_provider.dart';
import 'payment_webview_screen.dart';

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

  // Calculate amounts
  double getPayNowAmount(double items, double delivery) =>
      paymentType == "half" ? (items / 2) + delivery : items + delivery;

  double getPayLaterAmount(double items) =>
      paymentType == "half" ? items / 2 : 0;

  Future<void> payWithWebView(double amount) async {
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("Please log in to continue");

      final backendUrl =
          dotenv.env['BACKEND_URL'] ??
          "https://edgebaz-production.up.railway.app";

      final payUrl = backendUrl.endsWith('/')
          ? '${backendUrl}pay'
          : '$backendUrl/pay';
      print("💻 Hitting payment URL: $payUrl");

      final cartProvider = Provider.of<CartProvider>(context, listen: false);
      final productIds = cartProvider.items
          .map((item) => item.product.id)
          .toList();

      final body = {
        "amount": amount,
        "email": user.email ?? "user@example.com",
        "phone": widget.buyerPhone,
        "buyerName": widget.buyerName,
        "type": "normal",
        "productId": productIds,
        "paymentOption": paymentType,
        "deliveryAddress": widget.deliveryAddress,
        "buyerState": widget.buyerstate,
      };

      final response = await http.post(
        Uri.parse(payUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      print("💻 Response: ${response.statusCode} ${response.body}");

      if (response.statusCode != 200) {
        throw Exception("Server error: ${response.statusCode}");
      }

      final data = jsonDecode(response.body);
      if (data['status'] != 'success') {
        throw Exception(data['message'] ?? "Payment failed");
      }

      final paymentLink = data['data']?['link'] ?? data['link'];
      final txRef =
          data['tx_ref'] ?? "TX_${DateTime.now().millisecondsSinceEpoch}";
      if (paymentLink == null) throw Exception("No payment link returned");

      // Open payment in WebView
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentWebView(
            url: paymentLink,
            txRef: txRef,
            onPaymentResult: (status) async {
              if (status == "success") {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Payment successful! ✅")),
                );

                // Verify payment with backend
                final verifyUrl = backendUrl.endsWith('/')
                    ? '${backendUrl}verify-payment?tx_ref=$txRef'
                    : '$backendUrl/verify-payment?tx_ref=$txRef';

                final verifyResponse = await http.get(
                  Uri.parse(verifyUrl),
                  headers: {'Content-Type': 'application/json'},
                );

                if (verifyResponse.statusCode == 200) {
                  final verifyData = jsonDecode(verifyResponse.body);
                  print("✅ Payment verification result: $verifyData");
                } else {
                  print("❌ Verification failed: ${verifyResponse.statusCode}");
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Payment failed or cancelled ❌"),
                  ),
                );
              }
            },
          ),
        ),
      );
    } catch (e) {
      print("❌ ERROR: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("❌ ERROR: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);

    double itemsCost = 0;
    double deliveryCost = 0;

    for (var item in cartProvider.items) {
      final discount = item.product.discount ?? 0;
      final effectivePrice = item.product.price * (1 - discount / 100);
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
                  // Items List
                  Expanded(
                    child: ListView.builder(
                      itemCount: cartProvider.items.length,
                      itemBuilder: (context, index) {
                        final item = cartProvider.items[index];
                        final discount = item.product.discount ?? 0;
                        final effectivePrice =
                            item.product.price * (1 - discount / 100);

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

                  // Buyer Info
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

                  // Payment Type Selection
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile(
                          value: "full",
                          groupValue: paymentType,
                          onChanged: (value) =>
                              setState(() => paymentType = value!),
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
                              setState(() => paymentType = value!),
                          title: const Text(
                            "Half Payment",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Payment Breakdown
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

                  // Pay Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0A1D37),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: _isLoading
                          ? null
                          : () => payWithWebView(payNow),
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
