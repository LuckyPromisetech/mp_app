import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EditSellerAccountScreen extends StatefulWidget {
  const EditSellerAccountScreen({Key? key}) : super(key: key);

  @override
  State<EditSellerAccountScreen> createState() =>
      _EditSellerAccountScreenState();
}

class _EditSellerAccountScreenState extends State<EditSellerAccountScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final _formKey = GlobalKey<FormState>();

  final TextEditingController shopNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController shopDetailsController = TextEditingController();

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSellerData();
  }

  Future<void> _loadSellerData() async {
    final user = _auth.currentUser;
    if (user == null) return;

    emailController.text = user.email ?? "";

    final doc = await _firestore.collection('sellers').doc(user.uid).get();

    if (doc.exists) {
      final data = doc.data()!;
      shopNameController.text = data['shopName'] ?? "";
      shopDetailsController.text = data['shopDetails'] ?? "";
    }

    setState(() => _isLoading = false);
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    final user = _auth.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      // Update Firestore
      await _firestore.collection('sellers').doc(user.uid).update({
        "shopName": shopNameController.text.trim(),
        "shopDetails": shopDetailsController.text.trim(),
      });

      // Update email
      if (emailController.text.trim() != user.email) {
        await user.verifyBeforeUpdateEmail(emailController.text.trim());
      }

      // Update password if entered
      if (passwordController.text.isNotEmpty) {
        await user.updatePassword(passwordController.text.trim());
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Account updated successfully")),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    const kBackgroundColor = Color.fromARGB(255, 235, 137, 8);
    const kCardColor = Color(0xFF0D1B2A);

    return Scaffold(
      backgroundColor: kCardColor,

      appBar: AppBar(
        backgroundColor: kCardColor,
        iconTheme: const IconThemeData(
          color: kBackgroundColor, // ORANGE ARROW
        ),
        title: const Text(
          "Edit Seller Account",
          style: TextStyle(color: Colors.white),
        ),
      ),

      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),

              child: Form(
                key: _formKey,

                child: ListView(
                  children: [
                    /// SHOP NAME
                    TextFormField(
                      controller: shopNameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: "Shop Name",
                        labelStyle: TextStyle(color: Colors.orange),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.orange),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.orange),
                        ),
                      ),
                      validator: (value) =>
                          value!.isEmpty ? "Enter shop name" : null,
                    ),

                    const SizedBox(height: 16),

                    /// EMAIL
                    TextFormField(
                      controller: emailController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: "Email",
                        labelStyle: TextStyle(color: Colors.orange),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.orange),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.orange),
                        ),
                      ),
                      validator: (value) =>
                          value!.isEmpty ? "Enter email" : null,
                    ),

                    const SizedBox(height: 16),

                    /// PASSWORD
                    TextFormField(
                      controller: passwordController,
                      obscureText: true,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: "New Password",
                        labelStyle: TextStyle(color: Colors.orange),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.orange),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.orange),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    /// SHOP DETAILS
                    TextFormField(
                      controller: shopDetailsController,
                      maxLines: 3,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: "Shop Details",
                        labelStyle: TextStyle(color: Colors.orange),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.orange),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.orange),
                        ),
                      ),
                      validator: (value) =>
                          value!.isEmpty ? "Enter shop details" : null,
                    ),

                    const SizedBox(height: 25),

                    ElevatedButton(
                      onPressed: _saveChanges,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kBackgroundColor,
                        minimumSize: const Size.fromHeight(50),
                      ),
                      child: const Text(
                        "Save Changes",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
