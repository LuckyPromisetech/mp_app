import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mp_app/screens/seller_profile_screen.dart';
import 'dart:math';
import 'package:share_plus/share_plus.dart';

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:url_launcher/url_launcher.dart';

import 'add_product_screen.dart';
import 'seller_order_screen.dart';
import 'product_detail_screen.dart';
import '../models/products_model.dart';
import '../screens/verify_account_screen.dart';
import '../screens/edit_seller_account_screen.dart';
import 'verify_location_screen.dart';
import 'seller_profile_screen.dart';

class SellerScreen extends StatefulWidget {
  final String profileName;
  final String shopName;
  final String shopDetails;
  final String? storeId;

  const SellerScreen({
    Key? key,
    required this.profileName,
    required this.shopName,
    required this.shopDetails,
    this.storeId,
  }) : super(key: key);

  @override
  State<SellerScreen> createState() => _SellerScreenState();
}

class _SellerScreenState extends State<SellerScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<Map<String, dynamic>> sellerProducts = [];
  List<int> _currentImageIndex = [];
  bool _isLoading = true;

  int sellerStars = 0;
  double sellerDiscount = 0.0;
  DateTime? discountUntil;
  int followersCount = 0;

  bool _menuOpen = false;

  @override
  void initState() {
    super.initState();
    _fetchSellerProducts();
    _fetchSellerRating();
    _fetchFollowers();
  }

  Future<void> _fetchFollowers() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final doc = await _firestore.collection('sellers').doc(user.uid).get();
    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        followersCount = data['followersCount'] ?? 0;
      });
    }
  }

  // promote model
  void _openPromoteModal(Map<String, dynamic> product) {
    int selectedDuration = 1;
    double discount = 0.0;

    final TextEditingController discountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0D1B2A),
          title: const Text(
            'Promote Product',
            style: TextStyle(color: Colors.orange),
          ),
          content: StatefulBuilder(
            builder: (context, setState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      product['title'] ?? '',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),

                    const Text(
                      'Select duration:',
                      style: TextStyle(color: Colors.orangeAccent),
                    ),
                    const SizedBox(height: 6),

                    Wrap(
                      spacing: 10,
                      children: [
                        ChoiceChip(
                          label: const Text('1 Day - ₦1500'),
                          selected: selectedDuration == 1,
                          onSelected: (_) =>
                              setState(() => selectedDuration = 1),
                        ),
                        ChoiceChip(
                          label: const Text('3 Days - ₦3500'),
                          selected: selectedDuration == 3,
                          onSelected: (_) =>
                              setState(() => selectedDuration = 3),
                        ),
                        ChoiceChip(
                          label: const Text('7 Days - ₦5000'),
                          selected: selectedDuration == 7,
                          onSelected: (_) =>
                              setState(() => selectedDuration = 7),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    TextField(
                      controller: discountController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Discount (%)',
                        labelStyle: TextStyle(color: Colors.orangeAccent),
                      ),
                      onChanged: (value) {
                        final val = double.tryParse(value);
                        discount = (val != null && val >= 0 && val <= 100)
                            ? val
                            : 0;
                      },
                    ),
                  ],
                ),
              );
            },
          ),

          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.orange),
              ),
            ),

            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              onPressed: () async {
                await _handlePromotionPayment(
                  product: product,
                  duration: selectedDuration,
                  discount: discount,
                );
              },
              child: const Text('Promote'),
            ),
          ],
        );
      },
    );
  }

  /// promotion payment via hosted link
  Future<void> _handlePromotionPayment({
    required Map<String, dynamic> product,
    required int duration,
    required double discount,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Login required")));
      return;
    }

    try {
      /// 🔥 PRICE LOGIC
      final int amount = duration == 1
          ? 1500
          : duration == 3
          ? 3500
          : 5000;

      final txRef = "PROMO_${DateTime.now().millisecondsSinceEpoch}";

      /// ✅ SAFE ENV ACCESS (NO CRASH)
      String? backendUrl;

      try {
        backendUrl = dotenv.env['BACKEND_URL'];
      } catch (e) {
        print("❌ Dotenv not initialized: $e");
      }

      /// 🔥 FALLBACK (VERY IMPORTANT)
      backendUrl ??= "http://10.223.5.186"; // ← CHANGE THIS

      print("🌐 Backend URL: $backendUrl");

      final response = await http.post(
        Uri.parse('$backendUrl/promote'), // <-- change /pay to /promote
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "amount": amount,
          "email": user.email ?? "user@example.com",
          "tx_ref": txRef,
          "phone": user.phoneNumber ?? "08000000000",
          "productId": product['id'],
          "duration": duration,
          "discount": discount,
        }),
      );

      final data = jsonDecode(response.body);

      if (data['status'] != 'success') {
        throw Exception(data['message'] ?? "Failed to create payment link ❌");
      }

      final paymentLink = data['data']['link'];
      print("🔥 PAYMENT LINK: $paymentLink");

      /// 🔗 OPEN LINK
      final uri = Uri.parse(paymentLink);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw Exception("Could not launch payment link");
      }
    } catch (e) {
      print("❌ ERROR: $e");

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("❌ ERROR: $e")));
    }
  }

  /// saving promotion locally (optional if backend handles it)
  Future<void> _savePromotion(
    Map<String, dynamic> product,
    int duration,
    double discount,
  ) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final startDate = DateTime.now();
    final endDate = startDate.add(Duration(days: duration));

    await _firestore.collection('promoted_products').add({
      'productId': product['id'],
      'sellerId': user.uid,
      'title': product['title'],
      'imageUrl': product['imageUrl'],
      'price': product['price'],
      'discount': discount,
      'duration': duration,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'status': 'active',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _fetchSellerRating() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final sellerRef = _firestore.collection('sellers').doc(user.uid);
    final doc = await sellerRef.get();
    if (!doc.exists) return;

    final data = doc.data()!;
    final int successfulSales =
        data['successfulSales'] ?? 0; // total successful sales

    // Calculate stars: 1 star per 10 successful sales, max 6 stars
    int calculatedStars = (successfulSales ~/ 10);
    if (calculatedStars > 6) calculatedStars = 6;

    // Get previous stars
    int previousStars = data['stars'] ?? 0;

    DateTime? discountEnd;
    double discount = 0.0;

    final now = DateTime.now();

    // If seller earned a new star, give 2.5% discount for 1 week
    if (calculatedStars > previousStars) {
      discountEnd = now.add(const Duration(days: 7));
      discount = 0.025; // 2.5% discount
      await sellerRef.update({
        'stars': calculatedStars,
        'discountUntil': discountEnd,
      });
    } else {
      discountEnd = (data['discountUntil'] as Timestamp?)?.toDate();
      if (discountEnd != null && discountEnd.isAfter(now)) {
        discount =
            0.025 * calculatedStars; // current discount proportional to stars
      } else {
        discount = 0.0;
      }
    }

    setState(() {
      sellerStars = calculatedStars; // number of stars earned
      sellerDiscount = discount; // active discount
      discountUntil = discountEnd; // discount expiry
    });
  }

  Future<void> _fetchSellerProducts() async {
    setState(() => _isLoading = true);

    final user = _auth.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    final snapshot = await _firestore
        .collection('products')
        .where('sellerId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .get();

    setState(() {
      sellerProducts = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        data['quantity'] = data['quantity'] ?? 0;

        if (data['images'] == null || !(data['images'] is List)) {
          data['images'] = [];
        }

        return data;
      }).toList();

      _currentImageIndex = List.filled(sellerProducts.length, 0);
      _isLoading = false;
    });
  }

  Future<void> _deleteProduct(String id) async {
    try {
      await _firestore.collection('products').doc(id).delete();
      await _fetchSellerProducts();
    } catch (e) {
      debugPrint("Error deleting product: $e");
    }
  }

  Future<void> _increaseQuantity(int index) async {
    final product = sellerProducts[index];
    final newQuantity = (product['quantity'] ?? 0) + 1;

    try {
      await _firestore.collection('products').doc(product['id']).update({
        'quantity': newQuantity,
      });

      setState(() {
        sellerProducts[index]['quantity'] = newQuantity;
      });
    } catch (e) {
      debugPrint("Error increasing quantity: $e");
    }
  }

  Future<void> _decreaseQuantity(int index) async {
    final product = sellerProducts[index];
    final currentQty = (product['quantity'] ?? 0);

    if (currentQty > 0) {
      final newQuantity = currentQty - 1;
      try {
        await _firestore.collection('products').doc(product['id']).update({
          'quantity': newQuantity,
        });

        setState(() {
          sellerProducts[index]['quantity'] = newQuantity;
        });
      } catch (e) {
        debugPrint("Error decreasing quantity: $e");
      }
    }
  }

  Future<void> _addProduct({Map<String, dynamic>? product}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddProductScreen(product: product)),
    );

    if (result != null) {
      _fetchSellerProducts();
    }
  }

  void _nextImage(int productIndex) {
    final images = sellerProducts[productIndex]['images'] as List<dynamic>;
    if (images.isEmpty) return;

    setState(() {
      _currentImageIndex[productIndex] =
          (_currentImageIndex[productIndex] + 1) % images.length;
    });
  }

  String generateStoreId() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final rand = Random();
    return String.fromCharCodes(
      Iterable.generate(6, (_) => chars.codeUnitAt(rand.nextInt(chars.length))),
    );
  }

  void _openMenu() => setState(() => _menuOpen = true);
  void _closeMenu() => setState(() => _menuOpen = false);

  void _handleMenuSelection(String option) async {
    final user = _auth.currentUser;
    if (user == null) return;

    switch (option) {
      case "Verify account number":
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const VerifyAccountScreen()),
        );

        break;

      case "Verify Location":
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const VerifyLocationScreen()),
        );

        break;

      case "Store link":
        final currentUser = FirebaseAuth.instance.currentUser;

        if (currentUser == null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("Please login first")));
          return;
        }

        final docRef = _firestore.collection('sellers').doc(currentUser.uid);
        final doc = await docRef.get();

        // Create seller doc if not exists
        if (!doc.exists) {
          await docRef.set({'createdAt': FieldValue.serverTimestamp()});
        }

        String storeId = doc.data()?['storeId'] ?? '';

        // ✅ Generate storeId only once
        if (storeId.isEmpty) {
          storeId = "store_${currentUser.uid.substring(0, 8)}";

          await docRef.update({'storeId': storeId});
        }

        final link = "https://edgebaz.store/store/${currentUser.uid}";

        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: const Color(0xFF0D1B2A),
            title: const Text(
              "Store Link",
              style: TextStyle(color: Colors.orange),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SelectableText(
                  link,
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 10),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    /// COPY
                    IconButton(
                      icon: const Icon(Icons.copy, color: Colors.orange),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: link));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Link copied")),
                        );
                      },
                    ),

                    /// SHARE
                    IconButton(
                      icon: const Icon(Icons.share, color: Colors.orange),
                      onPressed: () {
                        Share.share("Check out my store: $link");
                      },
                    ),

                    /// OPEN (IN-APP)
                    IconButton(
                      icon: const Icon(Icons.open_in_new, color: Colors.orange),
                      onPressed: () {
                        SellerProfileScreen(sellerId: currentUser.uid);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
        break;

      case "Edit my seller account":
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const EditSellerAccountScreen()),
        );
        if (result == true) {
          _fetchSellerProducts(); // refresh in case shop name changed
        }
        break;
      case "Logout":
        await _auth.signOut();
        Navigator.pop(context);
        break;
      case "Close account":
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: const Color(0xFF0D1B2A),
            title: const Text(
              "Close Account",
              style: TextStyle(
                color: Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: const Text(
              "Please note that all products and info in this seller account will be permanently deleted.",
              style: TextStyle(color: Colors.white),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "Cancel",
                  style: TextStyle(color: Colors.white70),
                ),
              ),
              TextButton(
                onPressed: () async {
                  final user = _auth.currentUser;
                  if (user == null) return;

                  try {
                    // Delete all products of this seller
                    final productsSnapshot = await _firestore
                        .collection('products')
                        .where('sellerId', isEqualTo: user.uid)
                        .get();

                    for (var doc in productsSnapshot.docs) {
                      await _firestore
                          .collection('products')
                          .doc(doc.id)
                          .delete();
                    }

                    // Delete the seller document
                    await _firestore
                        .collection('sellers')
                        .doc(user.uid)
                        .delete();

                    // Sign out the user
                    await _auth.signOut();

                    Navigator.popUntil(
                      context,
                      (route) => route.isFirst,
                    ); // back to login/home
                  } catch (e) {
                    debugPrint("Error closing account: $e");
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Failed to close account")),
                    );
                  }
                },
                child: const Text(
                  "Delete",
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        );
        break;
    }

    _closeMenu();
  }

  @override
  Widget build(BuildContext context) {
    const kBackgroundColor = Color.fromARGB(255, 235, 137, 8);
    const kCardColor = Color(0xFF0D1B2A);
    const kTextColor = Colors.orange;

    return Stack(
      children: [
        Scaffold(
          backgroundColor: kCardColor,
          appBar: AppBar(
            backgroundColor: kCardColor,
            elevation: 0,
            iconTheme: const IconThemeData(color: kBackgroundColor),
            title: const Text(
              'Seller Dashboard',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.history, color: Colors.white),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SellerOrderScreen(),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onPressed: _openMenu,
              ),
            ],
          ),
          floatingActionButton: GestureDetector(
            onTap: () => _addProduct(),
            child: Container(
              height: 48,
              width: 170,
              decoration: BoxDecoration(
                color: kCardColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text(
                  "Create Product",
                  style: TextStyle(
                    color: kBackgroundColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerFloat,
          body: Column(
            children: [
              Container(
                color: kCardColor,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: kBackgroundColor,
                          child: Text(
                            widget.shopName.isNotEmpty
                                ? widget.shopName[0].toUpperCase()
                                : "S",
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.shopName,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: List.generate(6, (i) {
                                  return Icon(
                                    i < sellerStars
                                        ? Icons.star
                                        : Icons.star_border,
                                    color: kTextColor,
                                    size: 18,
                                  );
                                }),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "$followersCount followers",
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _auth.currentUser?.email ?? '',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.shopDetails,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 13,
                      ),
                    ),
                    if (sellerDiscount > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Discount active: ${(sellerDiscount * 100).toStringAsFixed(0)}% until ${discountUntil?.toLocal().toString().split(" ")[0]}',
                          style: const TextStyle(
                            color: Colors.greenAccent,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: kBackgroundColor,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(35),
                      topRight: Radius.circular(35),
                    ),
                  ),
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : sellerProducts.isEmpty
                      ? const Center(
                          child: Text(
                            'No products added yet.',
                            style: TextStyle(color: Colors.white),
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: sellerProducts.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 0.95,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                              ),
                          itemBuilder: (context, index) {
                            final product = sellerProducts[index];
                            final images = product['images'] as List<dynamic>;
                            final imageIndex = _currentImageIndex[index];
                            final imageToShow = images.isNotEmpty
                                ? images[imageIndex].toString()
                                : null;

                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ProductDetailScreen(
                                      product: Product(
                                        id: product['id'],
                                        title: product['title'] ?? '',
                                        description:
                                            product['description'] ?? '',
                                        price: (product['price'] ?? 0)
                                            .toDouble(),
                                        imageUrl: imageToShow ?? '',

                                        // ✅ REQUIRED FIELDS
                                        images: product['images'] != null
                                            ? List<String>.from(
                                                product['images'],
                                              )
                                            : [],

                                        weight: (product['weight'] ?? 1.0)
                                            .toDouble(),

                                        sellerId: product['sellerId'] ?? '',
                                        sellerstate:
                                            product['sellerstate'] ?? '',

                                        category: product['category'] ?? '',
                                        categoryId: product['categoryId'] ?? '',

                                        quantity: product['quantity'] ?? 1,
                                      ),
                                    ),
                                  ),
                                );
                              },
                              //product card
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: kCardColor,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 4,
                                      offset: Offset(2, 2),
                                    ),
                                  ],
                                ),

                                /// 🔥 FIXED STRUCTURE (NO OVERFLOW)
                                child: Column(
                                  children: [
                                    Expanded(
                                      child: SingleChildScrollView(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            /// IMAGE
                                            GestureDetector(
                                              onTap: () => _nextImage(index),
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                child: imageToShow != null
                                                    ? Image.network(
                                                        imageToShow,
                                                        height: 80,
                                                        width: double.infinity,
                                                        fit: BoxFit.cover,
                                                      )
                                                    : Container(
                                                        height: 80,
                                                        width: double.infinity,
                                                        color: Colors.grey[300],
                                                        child: const Icon(
                                                          Icons.image,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                              ),
                                            ),

                                            const SizedBox(height: 6),

                                            /// TITLE
                                            Text(
                                              product['title'] ?? '',
                                              style: const TextStyle(
                                                color: kTextColor,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),

                                            /// PRICE
                                            Text(
                                              '₦${product['price']}',
                                              style: const TextStyle(
                                                color: kTextColor,
                                                fontSize: 13,
                                              ),
                                            ),

                                            const SizedBox(height: 4),

                                            /// QUANTITY CONTROLS
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                IconButton(
                                                  padding: EdgeInsets.zero,
                                                  constraints:
                                                      const BoxConstraints(),
                                                  icon: const Icon(
                                                    Icons.remove,
                                                    size: 16,
                                                    color: kTextColor,
                                                  ),
                                                  onPressed: () =>
                                                      _decreaseQuantity(index),
                                                ),
                                                Text(
                                                  product['quantity']
                                                      .toString(),
                                                  style: const TextStyle(
                                                    color: kTextColor,
                                                  ),
                                                ),
                                                IconButton(
                                                  padding: EdgeInsets.zero,
                                                  constraints:
                                                      const BoxConstraints(),
                                                  icon: const Icon(
                                                    Icons.add,
                                                    size: 16,
                                                    color: kTextColor,
                                                  ),
                                                  onPressed: () =>
                                                      _increaseQuantity(index),
                                                ),
                                              ],
                                            ),

                                            const SizedBox(height: 6),

                                            /// EDIT + DELETE
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                TextButton(
                                                  onPressed: () => _addProduct(
                                                    product: product,
                                                  ),
                                                  child: const Text(
                                                    'Edit',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                                IconButton(
                                                  icon: const Icon(
                                                    Icons.delete,
                                                    color: Colors.red,
                                                    size: 18,
                                                  ),
                                                  onPressed: () =>
                                                      _deleteProduct(
                                                        product['id'],
                                                      ),
                                                ),
                                              ],
                                            ),

                                            /// 🔥 PROMOTE BUTTON (FULL WIDTH - CLEAN)
                                            SizedBox(
                                              width: double.infinity,
                                              child: TextButton(
                                                onPressed: () =>
                                                    _openPromoteModal(product),
                                                child: const Text(
                                                  'Promote',
                                                  style: TextStyle(
                                                    color: Colors.orangeAccent,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ),
            ],
          ),
        ),
        if (_menuOpen)
          GestureDetector(
            onTap: _closeMenu,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
              child: Container(
                color: Colors.black.withOpacity(0.4),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.6,
                      maxWidth: 220,
                    ),
                    child: Material(
                      color: kCardColor,
                      borderRadius: BorderRadius.circular(16),
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _menuItem("Verify account number"),
                            _menuItem("Verify Location"),
                            _menuItem("Edit my seller account"),
                            _menuItem("Store link"),
                            _menuItem("Logout"),
                            _menuItem("Close account"),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _menuItem(String text) {
    const kTextColor = Colors.orange;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _handleMenuSelection(text),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          alignment: Alignment.center,
          child: Text(
            text,
            style: const TextStyle(
              color: kTextColor,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}
