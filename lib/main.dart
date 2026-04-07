import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:app_links/app_links.dart';

import 'provider/cart_provider.dart';
import 'screens/user_wrapper.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: ".env");
    print("✅ .env loaded successfully");
  } catch (e) {
    print("❌ Error loading .env: $e");
  }

  if (kIsWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyB-_diQZ2QhSWqT6p5Ip_G03nM4_4cKYsg",
        authDomain: "mp-app-b9dcf.firebaseapp.com",
        projectId: "mp-app-b9dcf",
        storageBucket: "mp-app-b9dcf.appspot.com",
        messagingSenderId: "388466903099",
        appId: "1:388466903099:web:7f524eba1d0396765e341e",
        measurementId: "G-W3TCP0NRD3",
      ),
    );
  } else {
    await Firebase.initializeApp();
  }

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _sub;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  void _initDeepLinks() async {
    _appLinks = AppLinks();

    // 🔥 App opened from closed state
    try {
      final uri = await _appLinks.getInitialAppLink();
      if (uri != null) {
        _handleUri(uri);
      }
    } catch (e) {
      print("❌ Initial link error: $e");
    }

    // 🔥 App opened while running
    _sub = _appLinks.uriLinkStream.listen(
      (Uri uri) {
        _handleUri(uri);
      },
      onError: (err) {
        print("❌ Link stream error: $err");
      },
    );
  }

  void _handleUri(Uri uri) {
    print("🔗 Deep Link Received: $uri");

    if (uri.host == "payment-success") {
      final status = uri.queryParameters['status'];
      final txRef = uri.queryParameters['tx_ref'];

      print("✅ Payment Status: $status");
      print("🧾 TX REF: $txRef");

      if (status == "successful") {
        navigatorKey.currentState?.push(
          MaterialPageRoute(builder: (_) => const PaymentSuccessScreen()),
        );
      } else {
        navigatorKey.currentState?.push(
          MaterialPageRoute(builder: (_) => const PaymentFailedScreen()),
        );
      }
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => CartProvider())],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        title: 'MP Marketplace',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.green,
          useMaterial3: true,
          fontFamily: 'Arial',
        ),
        home: const UserWrapper(),
      ),
    );
  }
}

class PaymentSuccessScreen extends StatelessWidget {
  const PaymentSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Payment Success")),
      body: const Center(child: Text("Payment Successful 🎉")),
    );
  }
}

class PaymentFailedScreen extends StatelessWidget {
  const PaymentFailedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Payment Failed")),
      body: const Center(child: Text("Payment Failed ❌")),
    );
  }
}
