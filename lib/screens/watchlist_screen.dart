import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/products_model.dart';
import '../screens/product_detail_screen.dart';
import 'signup_sceen.dart';
import 'cart_screen.dart';
import 'bottom_nav_bar.dart';
import 'edit_account_screen.dart';
import 'following_sellers_screen.dart';

class WatchlistScreen extends StatefulWidget {
  const WatchlistScreen({Key? key}) : super(key: key);

  @override
  State<WatchlistScreen> createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends State<WatchlistScreen> {
  final Color orange = const Color(0xFFEB8908);
  final Color navy = const Color(0xFF0D1B2A);

  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// ===============================
  /// ACCOUNT MENU
  /// ===============================
  void _showAccountMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: navy,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            /// FOLLOWING SELLERS
            ListTile(
              leading: const Icon(Icons.people, color: Color(0xFFEB8908)),
              title: const Text(
                "Following Sellers",
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const FollowingSellersScreen(),
                  ),
                );
              },
            ),

            /// EDIT ACCOUNT
            ListTile(
              leading: const Icon(Icons.edit, color: Color(0xFFEB8908)),
              title: const Text(
                "Edit Account",
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);

                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EditAccountScreen()),
                );
              },
            ),

            /// LOGOUT
            ListTile(
              leading: const Icon(Icons.logout, color: Color(0xFFEB8908)),
              title: const Text(
                "Logout",
                style: TextStyle(color: Colors.white),
              ),
              onTap: () async {
                Navigator.pop(context);

                await FirebaseAuth.instance.signOut();

                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => SignUpScreen()),
                  (route) => false,
                );
              },
            ),

            /// CLOSE ACCOUNT
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text(
                "Close Account",
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                _confirmDeleteAccount();
              },
            ),
          ],
        );
      },
    );
  }

  /// ===============================
  /// CONFIRM DELETE POPUP
  /// ===============================
  void _confirmDeleteAccount() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: navy,
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
              child: const Text("Continue"),
            ),
          ],
        );
      },
    );
  }

  /// ===============================
  /// DELETE ACCOUNT
  /// ===============================
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

      /// DELETE AUTH ACCOUNT
      await user.delete();

      /// GO TO SIGNUP
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => SignUpScreen()),
        (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  /// ===============================
  /// UI
  /// ===============================
  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("Please log in to see your watchlist")),
      );
    }

    final watchlistQuery = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('watchlist')
        .orderBy('addedAt', descending: true);

    return Scaffold(
      backgroundColor: navy,

      body: SafeArea(
        child: Column(
          children: [
            /// HEADER
            Container(
              color: navy,
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Watchlist",
                    style: TextStyle(
                      color: Color(0xFFEB8908),
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  IconButton(
                    icon: const Icon(
                      Icons.shopping_cart,
                      color: Color(0xFFEB8908),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CartScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),

            /// WATCHLIST GRID
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: orange,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(40),
                    topRight: Radius.circular(40),
                  ),
                ),

                child: StreamBuilder<QuerySnapshot>(
                  stream: watchlistQuery.snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final watchlistDocs = snapshot.data!.docs;

                    if (watchlistDocs.isEmpty) {
                      return const Center(
                        child: Text(
                          "Your Watchlist is empty",
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      );
                    }

                    return GridView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: watchlistDocs.length,

                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.85,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),

                      itemBuilder: (context, index) {
                        final watchDoc = watchlistDocs[index];
                        final productId = watchDoc.id;

                        return FutureBuilder<DocumentSnapshot>(
                          future: FirebaseFirestore.instance
                              .collection('products')
                              .doc(productId)
                              .get(),

                          builder: (context, productSnapshot) {
                            if (!productSnapshot.hasData) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }

                            if (!productSnapshot.data!.exists) {
                              return const SizedBox();
                            }

                            final data =
                                productSnapshot.data!.data()
                                    as Map<String, dynamic>;

                            final product = Product.fromFirestore(
                              data,
                              productId,
                            );

                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        ProductDetailScreen(product: product),
                                  ),
                                );
                              },

                              child: Container(
                                decoration: BoxDecoration(
                                  color: navy,
                                  borderRadius: BorderRadius.circular(16),
                                ),

                                padding: const EdgeInsets.all(8),

                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    /// IMAGE
                                    Expanded(
                                      child: Stack(
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),

                                            child: Image.network(
                                              product.images.isNotEmpty
                                                  ? product.images[0]
                                                  : '',
                                              fit: BoxFit.cover,
                                              width: double.infinity,
                                            ),
                                          ),

                                          /// REMOVE
                                          Positioned(
                                            bottom: 6,
                                            right: 6,

                                            child: GestureDetector(
                                              onTap: () async {
                                                await FirebaseFirestore.instance
                                                    .collection('users')
                                                    .doc(user.uid)
                                                    .collection('watchlist')
                                                    .doc(productId)
                                                    .delete();
                                              },

                                              child: Container(
                                                padding: const EdgeInsets.all(
                                                  6,
                                                ),

                                                decoration: const BoxDecoration(
                                                  color: Colors.white70,
                                                  shape: BoxShape.circle,
                                                ),

                                                child: const Icon(
                                                  Icons.favorite,
                                                  size: 18,
                                                  color: Colors.red,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    const SizedBox(height: 6),

                                    /// TITLE
                                    Text(
                                      product.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Color(0xFFEB8908),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),

                                    /// PRICE
                                    Text(
                                      "₦${product.price}",
                                      style: const TextStyle(
                                        color: Color(0xFFEB8908),
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
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),

      bottomNavigationBar: BottomNavBar(
        parentContext: context,
        onAccountTap: _showAccountMenu,
      ),
    );
  }
}
