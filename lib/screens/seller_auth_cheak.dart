import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'seller_screen.dart';

class SellerAuthCheck extends StatefulWidget {
  const SellerAuthCheck({Key? key}) : super(key: key);

  @override
  State<SellerAuthCheck> createState() => _SellerAuthCheckState();
}

class _SellerAuthCheckState extends State<SellerAuthCheck> {
  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _checkSeller();
  }

  Future<void> _checkSeller() async {
    final user = supabase.auth.currentUser;

    // 1️⃣ Not logged in
    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please login first")));
      Navigator.pop(context);
      return;
    }

    // 2️⃣ Check if seller profile exists
    final response = await supabase
        .from('sellers')
        .select()
        .eq('user_id', user.id)
        .maybeSingle();

    if (!mounted) return;

    if (response == null) {
      // No seller profile → go to SignUp
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const SellerScreen()),
      );
    } else {
      // Seller exists → go to dashboard
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => SellerScreen(
            profileName: response['shop_name'],
            shopName: response['shop_name'],
            shopDetails: response['shop_details'] ?? '',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
