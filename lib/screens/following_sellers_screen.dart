import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'seller_profile_screen.dart';

class FollowingSellersScreen extends StatefulWidget {
  const FollowingSellersScreen({super.key});

  @override
  State<FollowingSellersScreen> createState() => _FollowingSellersScreenState();
}

class _FollowingSellersScreenState extends State<FollowingSellersScreen> {
  final Color navy = const Color(0xFF0D1B2A);
  final Color orange = const Color(0xFFEB8908);

  Widget buildStars(int stars) {
    // Build 6-star row, filled stars up to "stars"
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

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        final user = authSnapshot.data;

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
            title: const Text(
              "Following Sellers",
              style: TextStyle(color: Colors.white),
            ),
          ),
          body: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .collection('following')
                .snapshots(),
            builder: (context, followingSnapshot) {
              if (followingSnapshot.connectionState ==
                  ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!followingSnapshot.hasData ||
                  followingSnapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Text(
                    "You are not following any sellers yet",
                    style: TextStyle(color: Colors.white),
                  ),
                );
              }

              final followingDocs = followingSnapshot.data!.docs;

              return ListView.builder(
                itemCount: followingDocs.length,
                itemBuilder: (context, index) {
                  final sellerId = followingDocs[index]['sellerId'] ?? '';

                  return StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('sellers')
                        .doc(sellerId)
                        .snapshots(),
                    builder: (context, sellerSnapshot) {
                      if (sellerSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const ListTile(
                          title: Text(
                            "Loading...",
                            style: TextStyle(color: Colors.white),
                          ),
                        );
                      }

                      if (!sellerSnapshot.hasData ||
                          !sellerSnapshot.data!.exists) {
                        return const ListTile(
                          title: Text(
                            "Seller not found",
                            style: TextStyle(color: Colors.white),
                          ),
                        );
                      }

                      final sellerData =
                          sellerSnapshot.data!.data() as Map<String, dynamic>;

                      final shopName = sellerData['shopName'] ?? "Seller";
                      final shopDetails = sellerData['shopDetails'] ?? "";
                      final followersCount = sellerData['followersCount'] ?? 0;
                      final sellerStars = sellerData['stars'] ?? 0;

                      return ListTile(
                        leading: const Icon(
                          Icons.store,
                          color: Color(0xFFEB8908),
                        ),
                        title: Text(
                          shopName,
                          style: const TextStyle(color: Colors.white),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (shopDetails.isNotEmpty)
                              Text(
                                shopDetails,
                                style: const TextStyle(color: Colors.white70),
                              ),
                            const SizedBox(height: 2),
                            Text(
                              "$followersCount followers",
                              style: const TextStyle(color: Colors.white70),
                            ),
                            const SizedBox(height: 2),
                            // ⭐ Show seller rating stars
                            buildStars(sellerStars),
                          ],
                        ),
                        trailing: const Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.white70,
                          size: 16,
                        ),
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SellerProfileScreen(
                                sellerId: sellerId,
                                shopName: shopName,
                              ),
                            ),
                          );

                          // 🔥 Force refresh when back
                          setState(() {});
                        },
                      );
                    },
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}
