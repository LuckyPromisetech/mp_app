import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'seller_screen.dart';
import 'seller_login.dart';
import '../screens/home_screen.dart';

class SellerSignUpScreen extends StatefulWidget {
  const SellerSignUpScreen({Key? key}) : super(key: key);

  @override
  State<SellerSignUpScreen> createState() => _SellerSignUpScreenState();
}

class _SellerSignUpScreenState extends State<SellerSignUpScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController shopNameController = TextEditingController();
  final TextEditingController shopDetailsController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _signupSeller() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final user = userCredential.user;

      if (user != null) {
        await _firestore.collection('sellers').doc(user.uid).set({
          'email': emailController.text.trim(),
          'shopName': shopNameController.text.trim(),
          'shopDetails': shopDetailsController.text.trim(),
          'role': 'seller',
          'createdAt': FieldValue.serverTimestamp(),
        });

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => SellerScreen(
              profileName: emailController.text.trim(),
              shopName: shopNameController.text.trim(),
              shopDetails: shopDetailsController.text.trim(),
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Signup failed: $e')));
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 235, 137, 8),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF0D1B2A),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// 🔥 LOGO
                  Center(
                    child: Column(
                      children: [
                        Image.asset(
                          'assets/logo.png', // 👈 PUT YOUR LOGO HERE
                          height: 70,
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),

                  /// 🔙 BACK BUTTON
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.orange),
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const HomeScreen()),
                      );
                    },
                  ),

                  const SizedBox(height: 5),

                  const Text(
                    "Seller Sign Up",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 20),

                  _buildInput(
                    controller: shopNameController,
                    hint: "Shop Name",
                    validator: (value) =>
                        value!.isEmpty ? "Enter your shop name" : null,
                  ),

                  const SizedBox(height: 12),

                  /// ⚠️ EMAIL WARNING TEXT
                  const Text(
                    "Use a different email from your normal account",
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 6),

                  _buildInput(
                    controller: emailController,
                    hint: "Email",
                    validator: (value) =>
                        value!.contains('@') ? null : "Enter valid email",
                  ),

                  const SizedBox(height: 12),

                  TextFormField(
                    controller: passwordController,
                    obscureText: _obscurePassword,
                    style: const TextStyle(color: Colors.white),
                    validator: (value) =>
                        value!.length < 6 ? "Minimum 6 characters" : null,
                    decoration: InputDecoration(
                      hintText: "Password",
                      hintStyle: const TextStyle(color: Colors.white70),
                      filled: true,
                      fillColor: Colors.white10,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  _buildInput(
                    controller: shopDetailsController,
                    hint: "Shop Details",
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Enter shop details";
                      }

                      final pattern = RegExp(
                        r"(https?:\/\/|www\.|\.com|\.ng|wa\.me|whatsapp|t\.me|\+234\d{10}|0\d{10})",
                        caseSensitive: false,
                      );

                      if (pattern.hasMatch(value)) {
                        return "Links or contact info not allowed";
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 20),

                  _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Color.fromARGB(255, 231, 133, 5),
                          ),
                        )
                      : SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color.fromARGB(
                                255,
                                231,
                                133,
                                5,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: _signupSeller,
                            child: const Text(
                              "Sign Up",
                              style: TextStyle(color: Colors.black),
                            ),
                          ),
                        ),

                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SellerLoginScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      "Already have an account? Login",
                      style: TextStyle(color: Color.fromARGB(255, 231, 133, 5)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String hint,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.white10,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
