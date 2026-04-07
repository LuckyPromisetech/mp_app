import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

typedef PaymentCallback = void Function(String status);

class PaymentWebView extends StatefulWidget {
  final String url; // Payment URL from backend
  final String txRef; // Transaction reference for tracking
  final PaymentCallback onPaymentResult; // Callback for success/failure

  const PaymentWebView({
    super.key,
    required this.url,
    required this.txRef,
    required this.onPaymentResult,
  });

  @override
  State<PaymentWebView> createState() => _PaymentWebViewState();
}

class _PaymentWebViewState extends State<PaymentWebView> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _isLoading = true),
          onPageFinished: (_) => setState(() => _isLoading = false),
          onNavigationRequest: (request) {
            final url = request.url.toLowerCase();

            // ✅ Payment Success detection
            if (url.contains("status=successful") ||
                url.contains("status=completed")) {
              widget.onPaymentResult("success");
              Navigator.pop(context);
              return NavigationDecision.prevent;
            }

            // ❌ Payment Failed / Cancelled detection
            if (url.contains("status=failed") ||
                url.contains("status=cancelled")) {
              widget.onPaymentResult("failed");
              Navigator.pop(context);
              return NavigationDecision.prevent;
            }

            // Optional: Flutterwave specific redirect detection
            if (url.contains("flutterwave.com/payments/") &&
                url.contains("completed")) {
              widget.onPaymentResult("success");
              Navigator.pop(context);
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Complete Payment"),
        backgroundColor: const Color(0xFF0A1D37),
        iconTheme: const IconThemeData(color: Colors.orange),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.2),
              child: const Center(
                child: CircularProgressIndicator(
                  color: Colors.orange,
                  strokeWidth: 3,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
