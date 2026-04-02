// HomeScreen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../models/products_model.dart';
import '../screens/product_detail_screen.dart';
import '../screens/seller_screen.dart';
import '../screens/seller_login.dart';
import '../screens/seller_signup.dart';
import 'edit_account_screen.dart';
import '../screens/cart_screen.dart';
import '../screens/order_screen.dart';
import '../provider/cart_provider.dart';
import '../screens/watchlist_screen.dart';
import 'bottom_nav_bar.dart';
import 'following_sellers_screen.dart';
import 'signup_sceen.dart';
import 'admin_order_screen.dart';
import 'seller_profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;

  late Stream<List<Product>> _productsStream;

  final PageController _featuredController = PageController();
  final ScrollController _categoryController = ScrollController();
  final user = FirebaseAuth.instance.currentUser;
  final Stream<QuerySnapshot> _promoStream = FirebaseFirestore.instance
      .collection('promotions')
      .where('isActive', isEqualTo: true)
      .snapshots();

  Timer? _featuredTimer;
  Timer? _categoryTimer;

  int _featuredIndex = 0;
  String selectedCategory = '';

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();

    _productsStream = firestore
        .collection('products')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Product.fromFirestore(doc.data(), doc.id))
              .toList(),
        );

    _startFeaturedAutoSlide();
    _startCategoryAutoScroll();
    Stream<QuerySnapshot> _promoStream = FirebaseFirestore.instance
        .collection('promotions')
        .where('isActive', isEqualTo: true)
        .snapshots();
  }

  void _startFeaturedAutoSlide() {
    _featuredTimer = Timer.periodic(const Duration(seconds: 4), (Timer timer) {
      if (_featuredController.hasClients) {
        _featuredIndex++;
        _featuredController.animateToPage(
          _featuredIndex % 5,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void handleSearch(String input) {
    input = input.trim();

    /// 🔥 CHECK IF IT IS STORE LINK
    if (input.contains("edgebaz.store/store/")) {
      try {
        Uri uri = Uri.parse(input);

        /// Extract the LAST part of the link
        String sellerId = uri.pathSegments.last;

        if (sellerId.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SellerProfileScreen(
                sellerId: sellerId, // ✅ USE sellerId ONLY
              ),
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Invalid store link")));
      }
    } else {
      /// 🔎 NORMAL SEARCH
      setState(() {
        _searchQuery = input.toLowerCase();
      });
    }
  }

  void _startCategoryAutoScroll() {
    _categoryTimer = Timer.periodic(const Duration(milliseconds: 40), (timer) {
      if (!_categoryController.hasClients) return;

      final maxScroll = _categoryController.position.maxScrollExtent;
      final current = _categoryController.offset;

      double next = current - 1;

      if (current <= 5) {
        _categoryController.jumpTo(maxScroll);
      } else {
        _categoryController.jumpTo(next);
      }
    });
  }

  // Add product to Firestore watchlist
  Future<void> addToWatchlist(Map<String, dynamic> productData) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('watchlist')
        .doc(productData["productId"])
        .set(productData);
  }

  // Remove product from Firestore watchlist
  Future<void> removeFromWatchlist(String productId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('watchlist')
        .doc(productId)
        .delete();
  }

  Future<void> _openSellerFlow() async {
    final user = auth.currentUser;

    if (user == null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SellerLoginScreen()),
      );
      return;
    }

    final sellerDoc = await firestore.collection('sellers').doc(user.uid).get();

    if (!sellerDoc.exists) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SellerSignUpScreen()),
      );
    } else {
      final data = sellerDoc.data()!;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SellerScreen(
            profileName: data['email'] ?? '',
            shopName: data['shopName'] ?? '',
            shopDetails: data['shopDetails'] ?? '',
          ),
        ),
      );
    }
  }

  Future<List<String>> _fetchCategories() async {
    final snapshot = await firestore.collection('categories').get();
    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return (data['name'] ?? 'Unknown').toString();
    }).toList();
  }

  // HomeScreen.dart (continued from your code)

  /// Generate or fetch seller store link and show copy/share/open dialog
  Future<void> showStoreLinkDialog() async {
    final user = auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please log in as a seller first")),
      );
      return;
    }

    final docRef = firestore.collection('sellers').doc(user.uid);
    final doc = await docRef.get();

    // Create seller doc if it doesn't exist
    if (!doc.exists) {
      await docRef.set({});
    }

    /// 🔥 USE APP LINK (NOT WEBSITE)
    final storeLink = "Edgebaz://store?storeId=storeId";

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF0D1B2A),
        title: const Text("Store Link", style: TextStyle(color: Colors.orange)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SelectableText(
              storeLink,
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // COPY LINK
                IconButton(
                  icon: const Icon(Icons.copy, color: Colors.orange),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: storeLink));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Link copied")),
                    );
                  },
                ),

                // SHARE LINK
                IconButton(
                  icon: const Icon(Icons.share, color: Colors.orange),
                  onPressed: () {
                    Share.share("Check out my store: $storeLink");
                  },
                ),

                // OPEN STORE IN-APP
                IconButton(
                  icon: const Icon(Icons.open_in_new, color: Colors.orange),
                  onPressed: () {
                    openSellerStore(storeLink);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Navigate to seller store in-app using the store link
  Future<void> openSellerStore(String storeLink) async {
    try {
      Uri uri = Uri.parse(storeLink);

      /// 🔥 FIX: get from query not path
      String? storeId = uri.queryParameters['storeId'];

      if (storeId == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Invalid store link")));
        return;
      }

      final query = await FirebaseFirestore.instance
          .collection('sellers')
          .where('storeId', isEqualTo: storeId)
          .get();

      if (query.docs.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Seller not found")));
        return;
      }

      final data = query.docs.first.data();

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SellerScreen(
            profileName: data['email'] ?? '',
            shopName: data['shopName'] ?? '',
            shopDetails: data['shopDetails'] ?? '',
            storeId: storeId,
          ),
        ),
      );
    } catch (e) {
      debugPrint("Error opening seller store: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to open seller store")),
      );
    }
  }

  void _showAccountMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0D1B2A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.people, color: Color(0xFFEB8908)),
              title: const Text(
                "Following Sellers",
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context); // close menu

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const FollowingSellersScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit, color: Color(0xFFEB8908)),
              title: const Text(
                "Edit Account",
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context); // close the menu

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const EditAccountScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Color(0xFFEB8908)),
              title: const Text(
                "Logout",
                style: TextStyle(color: Colors.white),
              ),
              onTap: () async {
                Navigator.pop(context); // close menu

                await FirebaseAuth.instance.signOut();

                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => SignUpScreen()),
                  (route) => false,
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text(
                "Close Account",
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context); // close menu
                _confirmDeleteAccount();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _closeAccount() async {
    final user = FirebaseAuth.instance.currentUser;

    try {
      /// DELETE WATCHLIST
      final watchlist = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .collection('watchlist')
          .get();

      for (var doc in watchlist.docs) {
        await doc.reference.delete();
      }

      /// DELETE FOLLOWING
      final following = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('following')
          .get();

      for (var doc in following.docs) {
        await doc.reference.delete();
      }

      /// DELETE USER DOCUMENT
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .delete();

      /// DELETE FIREBASE AUTH ACCOUNT
      await user.delete();

      /// GO TO SIGNUP SCREEN
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const SignUpScreen()),
        (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  void _confirmDeleteAccount() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0D1B2A),

          title: const Text(
            "⚠️ Caution",
            style: TextStyle(color: Colors.white),
          ),

          content: const Text(
            "This action will delete everything about this account.\n\nDo you wish to continue?",
            style: TextStyle(color: Colors.white70),
          ),

          actions: [
            /// CANCEL
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text(
                "Cancel",
                style: TextStyle(color: Colors.white),
              ),
            ),

            /// CONTINUE
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEB8908),
              ),
              onPressed: () {
                Navigator.pop(context);
                _closeAccount();
              },
              child: const Text(
                "Continue",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);

    const orange = Color(0xFFEB8908);
    const navy = Color(0xFF0D1B2A);

    return Scaffold(
      backgroundColor: navy,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  setState(() {});
                },
                color: orange,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      Container(
                        color: navy,
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            /// HEADER
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                GestureDetector(
                                  onLongPress: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const AdminOrderScreen(),
                                      ),
                                    );
                                  },
                                  child: const Icon(Icons.home),
                                ),
                                Row(
                                  children: [
                                    /// CART
                                    Stack(
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                            Icons.shopping_cart,
                                            color: orange,
                                          ),
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    const CartScreen(),
                                              ),
                                            );
                                          },
                                        ),
                                        if (cart.items.isNotEmpty)
                                          Positioned(
                                            right: 4,
                                            top: 4,
                                            child: CircleAvatar(
                                              radius: 8,
                                              backgroundColor: Colors.red,
                                              child: Text(
                                                cart.items.length.toString(),
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),

                                    const SizedBox(width: 12),

                                    /// ORDERS
                                    IconButton(
                                      icon: const Icon(
                                        Icons.receipt_long,
                                        color: Color(0xFFEB8908),
                                      ),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => const OrderScreen(),
                                          ),
                                        );
                                      },
                                    ),

                                    const SizedBox(width: 12),

                                    /// SELLER
                                    IconButton(
                                      icon: const Icon(
                                        Icons.store,
                                        color: Color(0xFFEB8908),
                                      ),
                                      onPressed: _openSellerFlow,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            /// SEARCH
                            TextField(
                              controller: _searchController,
                              onChanged: (val) {
                                setState(
                                  () => _searchQuery = val.toLowerCase(),
                                );
                              },

                              /// 🔥 HANDLE ENTER / SUBMIT
                              onSubmitted: (input) {
                                handleSearch(input);
                              },

                              decoration: InputDecoration(
                                hintText:
                                    "Search products, categories or paste store link",
                                prefixIcon: const Icon(
                                  Icons.search,
                                  color: orange,
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),

                            const SizedBox(height: 20),

                            /// PROMOTED PRODUCTS
                            SizedBox(
                              height: 140,
                              child: StreamBuilder<QuerySnapshot>(
                                stream: FirebaseFirestore.instance
                                    .collection('promoted_products')
                                    .where('status', isEqualTo: 'active')
                                    .orderBy('startDate', descending: true)
                                    .snapshots(),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return const Center(
                                      child: CircularProgressIndicator(
                                        color: orange,
                                      ),
                                    );
                                  }

                                  final docs = snapshot.data?.docs ?? [];

                                  /// 🔥 FILTER ACTIVE PROMOTIONS & LIMIT TO 10
                                  final promos = docs
                                      .where((doc) {
                                        final data =
                                            doc.data() as Map<String, dynamic>;
                                        if (data['endDate'] == null)
                                          return false;
                                        final endDate =
                                            (data['endDate'] as Timestamp)
                                                .toDate();
                                        return endDate.isAfter(DateTime.now());
                                      })
                                      .take(10)
                                      .toList();

                                  /// 🔥 EMPTY STATE PLACEHOLDERS
                                  if (promos.isEmpty) {
                                    return ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: 3,
                                      itemBuilder: (context, index) =>
                                          Container(
                                            width: 120,
                                            margin: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 10,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white10,
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                          ),
                                    );
                                  }

                                  final PageController controller =
                                      PageController(viewportFraction: 0.7);

                                  return PageView.builder(
                                    controller: controller,
                                    itemCount: promos.length,
                                    itemBuilder: (context, index) {
                                      final promoData =
                                          promos[index].data()
                                              as Map<String, dynamic>;
                                      final productId = promoData['productId'];
                                      final discount =
                                          (promoData['discount'] ?? 0).toInt();

                                      /// 🔥 FETCH REAL PRODUCT DATA
                                      return StreamBuilder<DocumentSnapshot>(
                                        stream: FirebaseFirestore.instance
                                            .collection('products')
                                            .doc(productId)
                                            .snapshots(),
                                        builder: (context, productSnap) {
                                          if (!productSnap.hasData ||
                                              !productSnap.data!.exists) {
                                            return const SizedBox();
                                          }

                                          final productData =
                                              productSnap.data!.data()
                                                  as Map<String, dynamic>;
                                          final title =
                                              productData['title'] ?? '';
                                          final price =
                                              (productData['price'] ?? 0)
                                                  .toDouble();
                                          final quantity =
                                              (productData['quantity'] ?? 0)
                                                  .toInt();
                                          final image =
                                              (productData['images'] != null &&
                                                  productData['images']
                                                      .isNotEmpty)
                                              ? productData['images'][0]
                                              : null;

                                          return GestureDetector(
                                            behavior:
                                                HitTestBehavior.translucent,
                                            onTap: () {
                                              final product = Product(
                                                id: productId,
                                                title: title,
                                                images: List<String>.from(
                                                  productData['images'] ?? [],
                                                ),
                                                price: price,
                                                discount: discount,
                                                quantity: quantity,
                                                category:
                                                    productData['category'] ??
                                                    '',
                                                description:
                                                    productData['description'] ??
                                                    '',
                                                imageUrl: image ?? '',
                                                sellerstate:
                                                    productData['sellerstate'] ??
                                                    '',
                                                sellerId:
                                                    productData['sellerId'] ??
                                                    '',
                                              );

                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      ProductDetailScreen(
                                                        product: product,
                                                      ),
                                                ),
                                              );
                                            },
                                            child: Container(
                                              margin:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 10,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.white10,
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              child: Stack(
                                                children: [
                                                  /// IMAGE
                                                  ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          20,
                                                        ),
                                                    child: image != null
                                                        ? Image.network(
                                                            image,
                                                            width:
                                                                double.infinity,
                                                            height:
                                                                double.infinity,
                                                            fit: BoxFit.cover,
                                                            errorBuilder:
                                                                (
                                                                  _,
                                                                  __,
                                                                  ___,
                                                                ) => Container(
                                                                  color: Colors
                                                                      .grey,
                                                                  child: const Center(
                                                                    child: Icon(
                                                                      Icons
                                                                          .image,
                                                                      color: Colors
                                                                          .white,
                                                                    ),
                                                                  ),
                                                                ),
                                                          )
                                                        : Container(
                                                            color: Colors.grey,
                                                            child: const Center(
                                                              child: Icon(
                                                                Icons.image,
                                                                color: Colors
                                                                    .white,
                                                              ),
                                                            ),
                                                          ),
                                                  ),

                                                  /// SEMI-TRANSPARENT OVERLAY
                                                  Container(
                                                    decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            20,
                                                          ),
                                                      color: Colors.black
                                                          .withOpacity(0.3),
                                                    ),
                                                  ),

                                                  /// TITLE
                                                  Center(
                                                    child: Padding(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 10,
                                                          ),
                                                      child: Text(
                                                        title,
                                                        textAlign:
                                                            TextAlign.center,
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 16,
                                                        ),
                                                      ),
                                                    ),
                                                  ),

                                                  /// DISCOUNT BADGE
                                                  if (discount > 0)
                                                    Positioned(
                                                      top: 8,
                                                      right: 8,
                                                      child: Container(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 8,
                                                              vertical: 4,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          color: Colors.black,
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                12,
                                                              ),
                                                        ),
                                                        child: Text(
                                                          "-$discount%",
                                                          style:
                                                              const TextStyle(
                                                                color: orange,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                fontSize: 12,
                                                              ),
                                                        ),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),

                      /// ORANGE SECTION
                      Container(
                        decoration: const BoxDecoration(
                          color: orange,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(40),
                            topRight: Radius.circular(40),
                          ),
                        ),
                        child: Column(
                          children: [
                            /// CATEGORY SECTION
                            SizedBox(
                              height: 60,
                              child: FutureBuilder<List<String>>(
                                future: _fetchCategories(),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return const Center(
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                      ),
                                    );
                                  }

                                  final categories = snapshot.data ?? [];

                                  if (categories.isEmpty) {
                                    return const Center(
                                      child: Text(
                                        "No categories",
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    );
                                  }

                                  return ListView.builder(
                                    controller: _categoryController,
                                    scrollDirection: Axis.horizontal,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    itemCount: categories.length,
                                    itemBuilder: (context, index) {
                                      final category = categories[index];
                                      return _categoryCard(category);
                                    },
                                  );
                                },
                              ),
                            ),

                            /// PRODUCTS GRID
                            StreamBuilder<List<Product>>(
                              stream: _productsStream,
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Center(
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                    ),
                                  );
                                }
                                final products = (snapshot.data ?? []).where((
                                  p,
                                ) {
                                  final matchesSearch =
                                      p.title.toLowerCase().contains(
                                        _searchQuery,
                                      ) ||
                                      p.category.toLowerCase().contains(
                                        _searchQuery,
                                      );

                                  final matchesCategory =
                                      selectedCategory.isEmpty ||
                                      p.category == selectedCategory;

                                  return matchesSearch && matchesCategory;
                                }).toList();

                                return GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  padding: const EdgeInsets.all(12),
                                  itemCount: products.length,
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 2,
                                        childAspectRatio: 0.85,
                                        crossAxisSpacing: 12,
                                        mainAxisSpacing: 12,
                                      ),
                                  itemBuilder: (context, index) {
                                    final product = products[index];

                                    final qty = product.quantity ?? 0;
                                    final qtyColor = qty < 5
                                        ? Colors.red
                                        : Colors.yellow;

                                    return GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => ProductDetailScreen(
                                              product: product,
                                            ),
                                          ),
                                        );
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF0D1B2A),
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                        padding: const EdgeInsets.all(8),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: Stack(
                                                children: [
                                                  ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                    child: Image.network(
                                                      product.images.isNotEmpty
                                                          ? product.images.first
                                                          : '',
                                                      fit: BoxFit.cover,
                                                      width: double.infinity,
                                                      errorBuilder:
                                                          (
                                                            _,
                                                            __,
                                                            ___,
                                                          ) => Container(
                                                            color: Colors.grey,
                                                            child: const Center(
                                                              child: Icon(
                                                                Icons.image,
                                                                size: 40,
                                                                color: Colors
                                                                    .white,
                                                              ),
                                                            ),
                                                          ),
                                                    ),
                                                  ),

                                                  // Quantity tag
                                                  Positioned(
                                                    top: 6,
                                                    right: 6,
                                                    child: Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 6,
                                                            vertical: 3,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: qtyColor,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              6,
                                                            ),
                                                      ),
                                                      child: Text(
                                                        qty.toString(),
                                                        style: const TextStyle(
                                                          color: Colors.black,
                                                          fontSize: 10,
                                                        ),
                                                      ),
                                                    ),
                                                  ),

                                                  // Watchlist toggle ❤️
                                                  Positioned(
                                                    bottom: 6,
                                                    right: 6,
                                                    child: Consumer<CartProvider>(
                                                      builder: (_, provider, __) {
                                                        final isFavorite =
                                                            provider.watchlist
                                                                .any(
                                                                  (p) =>
                                                                      p.id ==
                                                                      product
                                                                          .id,
                                                                );

                                                        return GestureDetector(
                                                          onTap: () async {
                                                            final user =
                                                                FirebaseAuth
                                                                    .instance
                                                                    .currentUser;

                                                            if (user == null)
                                                              return;

                                                            final watchlistRef =
                                                                FirebaseFirestore
                                                                    .instance
                                                                    .collection(
                                                                      'users',
                                                                    )
                                                                    .doc(
                                                                      user.uid,
                                                                    )
                                                                    .collection(
                                                                      'watchlist',
                                                                    )
                                                                    .doc(
                                                                      product
                                                                          .id,
                                                                    );

                                                            if (isFavorite) {
                                                              /// REMOVE
                                                              provider
                                                                  .removeFromWatchlist(
                                                                    product,
                                                                  );

                                                              await watchlistRef
                                                                  .delete();
                                                            } else {
                                                              /// ADD
                                                              provider
                                                                  .addToWatchlist(
                                                                    product,
                                                                  );

                                                              await watchlistRef
                                                                  .set({
                                                                    "addedAt":
                                                                        FieldValue.serverTimestamp(),
                                                                  });
                                                            }
                                                          },
                                                          child: Container(
                                                            padding:
                                                                const EdgeInsets.all(
                                                                  6,
                                                                ),
                                                            decoration: BoxDecoration(
                                                              color: isFavorite
                                                                  ? Colors
                                                                        .redAccent
                                                                  : Colors
                                                                        .white70,
                                                              shape: BoxShape
                                                                  .circle,
                                                            ),
                                                            child: Icon(
                                                              Icons.favorite,
                                                              size: 18,
                                                              color: isFavorite
                                                                  ? Colors.white
                                                                  : Colors
                                                                        .black,
                                                            ),
                                                          ),
                                                        );
                                                      },
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              product.title,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                color: orange,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              "₦${product.price}",
                                              style: const TextStyle(
                                                color: orange,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),

      /// BOTTOM NAVIGATION ROW
      bottomNavigationBar: BottomNavBar(
        parentContext: context,
        onHomeTap: () {
          setState(() {}); // refresh home if needed
        },
        onAccountTap:
            _showAccountMenu, // call your existing account menu function
      ),
    );
  }

  /// CATEGORY CARD (TEXT ONLY)
  Widget _categoryCard(String title) {
    return GestureDetector(
      onTap: () {
        setState(() => selectedCategory = title);
      },
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: selectedCategory == title
              ? Colors.white
              : const Color(0xFF0D1B2A),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: selectedCategory == title ? Colors.black : Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
