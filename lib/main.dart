import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'provider/cart_provider.dart';
import 'screens/user_wrapper.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  try {
    await dotenv.load(fileName: ".env");
    print("✅ .env loaded successfully");
  } catch (e) {
    print("❌ Error loading .env: $e");
  }

  // Initialize Firebase
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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => CartProvider())],
      child: MaterialApp(
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
