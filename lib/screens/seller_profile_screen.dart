import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/products_model.dart';
import 'product_detail_screen.dart';

class SellerProfileScreen extends StatefulWidget {
  final String sellerId; // ✅ BACK TO NORMAL
  final String? shopName;

  const SellerProfileScreen({super.key, required this.sellerId, this.shopName});

  @override
  State<SellerProfileScreen> createState() => _SellerProfileScreenState();
}

class _SellerProfileScreenState extends State<SellerProfileScreen> {
  final Color navy = const Color(0xFF0D1B2A);
  final Color orange = const Color(0xFFEB8908);

  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  /// Build stars
  Widget buildStars(int stars) {
    return Row(
      children: List.generate(
        6,
        (index) => Icon(
          index < stars ? Icons.star : Icons.star_border,
          color: Colors.orange,
          size: 16,
        ),
      ),
    );
  }

  int calculateStars(int sales) {
    int stars = sales ~/ 10;
    if (stars > 6) stars = 6;
    return stars;
  }

  /// Follow toggle
  Future<void> toggleFollow(bool isFollowing) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final sellerRef = _firestore.collection('sellers').doc(widget.sellerId);

    final userFollowingRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('following')
        .doc(widget.sellerId);

    if (isFollowing) {
      await sellerRef.update({
        'followers': FieldValue.arrayRemove([user.uid]),
        'followersCount': FieldValue.increment(-1),
      });
      await userFollowingRef.delete();
    } else {
      await sellerRef.update({
        'followers': FieldValue.arrayUnion([user.uid]),
        'followersCount': FieldValue.increment(1),
      });
      await userFollowingRef.set({
        'sellerId': widget.sellerId,
        'followedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  /// Watchlist
  Future<void> toggleWatchlist(String productId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final docRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('watchlist')
        .doc(productId);

    final exists = await docRef.get();

    if (exists.exists) {
      await docRef.delete();
    } else {
      await docRef.set({
        'productId': productId,
        'addedAt': FieldValue.serverTimestamp(),
      });
    }

    setState(() {});
  }

  Future<bool> isInWatchlist(String productId) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final doc = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('watchlist')
        .doc(productId)
        .get();

    return doc.exists;
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    if (user == null) {
      return Scaffold(
        backgroundColor: navy,
        body: const Center(
          child: Text(
            "You are not logged in",
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: navy,
      appBar: AppBar(
        backgroundColor: navy,
        title: Text(
          widget.shopName ?? "Shop",
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: Column(
        children: [
          /// SELLER HEADER
          StreamBuilder<DocumentSnapshot>(
            stream: _firestore
                .collection('sellers')
                .doc(widget.sellerId)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || !snapshot.data!.exists) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    "Seller not found",
                    style: TextStyle(color: Colors.white),
                  ),
                );
              }

              final data = snapshot.data!.data() as Map<String, dynamic>;

              final shopName = data['shopName'] ?? "Shop";
              final shopDetails = data['shopDetails'] ?? '';
              final followersCount = data['followersCount'] ?? 0;
              final followers = data['followers'] ?? [];

              final isFollowing = followers.contains(user.uid);

              final sales = data['successfulSales'] ?? 0;
              final stars = calculateStars(sales);

              return Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            shopName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (shopDetails.isNotEmpty)
                            Text(
                              shopDetails,
                              style: const TextStyle(color: Colors.white70),
                            ),
                          const SizedBox(height: 4),
                          Text(
                            "$followersCount followers",
                            style: const TextStyle(color: Colors.white70),
                          ),
                          buildStars(stars),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: orange),
                      onPressed: () => toggleFollow(isFollowing),
                      child: Text(
                        isFollowing ? "Following" : "Follow",
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          /// PRODUCTS
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('products')
                  .where('sellerId', isEqualTo: widget.sellerId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      "No products yet",
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                }

                final products = snapshot.data!.docs;

                return GridView.builder(
                  padding: const EdgeInsets.all(10),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final doc = products[index];
                    final data = doc.data() as Map<String, dynamic>;

                    final product = Product.fromFirestore(data, doc.id);

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
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Expanded(
                              child: Image.network(
                                product.imageUrl,
                                fit: BoxFit.cover,
                                width: double.infinity,
                              ),
                            ),
                            Text(product.title),
                            Text("₦${product.price}"),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
