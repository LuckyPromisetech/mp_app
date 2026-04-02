import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import '../models/products_model.dart';
import '../provider/cart_provider.dart';
import 'cart_screen.dart';
import 'seller_profile_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({Key? key, required this.product})
    : super(key: key);

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int quantity = 1;
  int currentImageIndex = 0;

  final TextEditingController addressController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();

  double deliveryPrice = 0;

  String? selectedState;
  String sellerState = "";

  void addToCart() {
    final user = FirebaseAuth.instance.currentUser;

    Provider.of<CartProvider>(
      context,
      listen: false,
    ).addToCart(widget.product, quantity, deliveryPrice, user!.uid);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${widget.product.title} added to cart x$quantity'),
      ),
    );
  }

  void incrementQuantity() {
    setState(() {
      quantity++;
    });
  }

  void decrementQuantity() {
    if (quantity > 1) {
      setState(() {
        quantity--;
      });
    }
  }

  // 🔥 DELIVERY LOGIC WITH WEIGHT
  void calculateDeliveryPrice(String buyerState, double productWeight) {
    selectedState = buyerState;

    if (sellerState.isEmpty) return;

    // State-based delivery
    if (buyerState == sellerState) {
      deliveryPrice = 2500;
    } else if (isNearbyState(buyerState, sellerState)) {
      deliveryPrice = 4500;
    } else {
      deliveryPrice = 6000;
    }

    // Weight-based addition
    if (productWeight <= 1) {
      deliveryPrice += 500;
    } else if (productWeight > 1 && productWeight <= 3) {
      deliveryPrice += 700;
    } else if (productWeight > 3 && productWeight <= 5) {
      deliveryPrice += 1000;
    } else if (productWeight > 5) {
      deliveryPrice += 1500;
    }

    setState(() {});
  }

  bool isNearbyState(String buyer, String seller) {
    Map<String, List<String>> nearbyStates = {
      "Anambra": ["Enugu", "Imo", "Delta", "Abia"],
      "Lagos": ["Ogun", "Oyo"],
      "Abuja": ["Nasarawa", "Kogi"],
    };

    return nearbyStates[seller]?.contains(buyer) ?? false;
  }

  @override
  void dispose() {
    addressController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color orange = const Color(0xFFFF8C00);
    Color navy = const Color(0xFF0A1D37);

    final List<String> images = widget.product.images.isNotEmpty
        ? widget.product.images
        : [widget.product.imageUrl];

    return Scaffold(
      backgroundColor: orange,
      appBar: AppBar(
        backgroundColor: navy,
        iconTheme: IconThemeData(color: orange),
        title: Text("Product Details", style: TextStyle(color: orange)),
        actions: [
          IconButton(
            icon: Icon(Icons.favorite_border, color: orange),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.shopping_cart, color: orange),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CartScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Images
              Center(
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        height: 230,
                        width: double.infinity,
                        child: PageView.builder(
                          itemCount: images.length,
                          onPageChanged: (index) =>
                              setState(() => currentImageIndex = index),
                          itemBuilder: (context, index) {
                            return Image.network(
                              images[index],
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                    color: Colors.grey[300],
                                    child: const Icon(Icons.image, size: 50),
                                  ),
                            );
                          },
                        ),
                      ),
                    ),

                    // 🔥 PROMOTED BADGE
                    if (widget.product.isPromoted == true)
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            "PROMOTED",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),

                    if (images.length > 1)
                      Positioned(
                        bottom: 8,
                        child: Row(
                          children: List.generate(images.length, (index) {
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              width: currentImageIndex == index ? 12 : 8,
                              height: currentImageIndex == index ? 12 : 8,
                              decoration: BoxDecoration(
                                color: currentImageIndex == index
                                    ? orange
                                    : Colors.white,
                                shape: BoxShape.circle,
                              ),
                            );
                          }),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Product Name & Price
              Text(
                widget.product.title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              // ONLY showing modified parts clearly integrated

              // ================= PRICE SECTION =================
              Builder(
                builder: (context) {
                  double originalPrice = widget.product.price;
                  double discount =
                      (widget.product.discount ?? 0) / 100; // convert %
                  double discountedPrice =
                      originalPrice - (originalPrice * discount);

                  return Row(
                    children: [
                      if (discount > 0)
                        Text(
                          '₦${originalPrice.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      if (discount > 0) const SizedBox(width: 8),
                      Text(
                        '₦${discount > 0 ? discountedPrice.toStringAsFixed(0) : originalPrice.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 22,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (discount > 0) const SizedBox(width: 8),
                      if (discount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '-${(discount * 100).toInt()}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              // Product Details
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: navy,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Product Details",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      widget.product.description.isNotEmpty
                          ? widget.product.description
                          : 'No description available',
                      style: const TextStyle(fontSize: 16, color: Colors.white),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Category: ${widget.product.category}",
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      "${widget.product.quantity} left",
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Delivery Address with State Dropdown
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: addressController,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        icon: Icon(Icons.location_on),
                        hintText: "Enter Delivery Address",
                      ),
                    ),
                    const SizedBox(height: 10),
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('states')
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const SizedBox();
                        final states = snapshot.data!.docs;
                        return DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: "Select State",
                          ),
                          items: states.map((doc) {
                            return DropdownMenuItem<String>(
                              value: doc.id,
                              child: Text(doc.id),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              calculateDeliveryPrice(
                                value,
                                widget.product.weight,
                              ); // ✅ pass weight here
                            }
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    if (deliveryPrice > 0)
                      Text(
                        "Delivery Price: ₦${(deliveryPrice * quantity).toStringAsFixed(0)}",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Seller Info
              FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('sellers')
                    .doc(widget.product.sellerId)
                    .get(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || !snapshot.data!.exists) {
                    return const Text(
                      "Seller not found",
                      style: TextStyle(color: Colors.white),
                    );
                  }

                  final sellerData =
                      snapshot.data!.data() as Map<String, dynamic>;

                  final sellerName = sellerData['shopName'] ?? "Seller";
                  final shopDetails = sellerData['shopDetails'] ?? "";
                  sellerState = sellerData['state'] ?? "";

                  final int followersCount = sellerData['followersCount'] ?? 0;
                  final int successfulSales =
                      sellerData['successfulSales'] ?? 0;

                  // ⭐ Calculate stars: 1 star per 10 successful sales, max 6 stars
                  int stars = successfulSales ~/ 10;
                  if (stars > 6) stars = 6;
                  double decimalRating = (successfulSales / 10);
                  if (decimalRating > 6) decimalRating = 6;

                  final user = FirebaseAuth.instance.currentUser;
                  bool isFollowing = false;
                  if (user != null) {
                    final followersList = sellerData['followers'] ?? [];
                    isFollowing = followersList.contains(user.uid);
                  }

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SellerProfileScreen(
                            sellerId: widget.product.sellerId,
                            shopName: sellerName,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const CircleAvatar(
                            radius: 22,
                            child: Icon(Icons.store),
                          ),
                          const SizedBox(width: 12),

                          /// SELLER DETAILS
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  sellerName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),

                                Text(
                                  shopDetails,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),

                                /// ⭐ DYNAMIC SELLER RATING
                                Row(
                                  children: [
                                    Row(
                                      children: List.generate(
                                        6,
                                        (index) => Icon(
                                          index < stars
                                              ? Icons.star
                                              : Icons.star_border,
                                          color: Colors.orange,
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      decimalRating.toStringAsFixed(1) +
                                          " Seller Rating",
                                      style: const TextStyle(
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),

                                Text(
                                  "$followersCount followers",
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          /// FOLLOW BUTTON
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: orange,
                            ),
                            onPressed: () async {
                              if (user == null) return;

                              final sellerRef = FirebaseFirestore.instance
                                  .collection('sellers')
                                  .doc(widget.product.sellerId);

                              final userFollowingRef = FirebaseFirestore
                                  .instance
                                  .collection('users')
                                  .doc(user.uid)
                                  .collection('following')
                                  .doc(widget.product.sellerId);

                              if (isFollowing) {
                                /// 🔻 UNFOLLOW
                                await sellerRef.update({
                                  'followers': FieldValue.arrayRemove([
                                    user.uid,
                                  ]),
                                  'followersCount': FieldValue.increment(-1),
                                });

                                await userFollowingRef
                                    .delete(); // ✅ REMOVE FROM LIST
                              } else {
                                /// 🔺 FOLLOW
                                await sellerRef.update({
                                  'followers': FieldValue.arrayUnion([
                                    user.uid,
                                  ]),
                                  'followersCount': FieldValue.increment(1),
                                });

                                await userFollowingRef.set({
                                  'sellerId': widget.product.sellerId,
                                  'followedAt': FieldValue.serverTimestamp(),
                                }); // ✅ ADD TO LIST
                              }

                              setState(() {}); // refresh UI
                            },
                            child: Text(isFollowing ? "Following" : "Follow"),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),

              // Quantity Selector
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Quantity",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove),
                          onPressed: decrementQuantity,
                        ),
                        Text(
                          quantity.toString(),
                          style: const TextStyle(fontSize: 16),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: incrementQuantity,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // COMMENTS SECTION
              Text(
                "Comments",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),

              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('products')
                    .doc(widget.product.id)
                    .collection('comments')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Text(
                      "No comments yet. Be the first to comment!",
                      style: TextStyle(color: Colors.white),
                    );
                  }

                  final comments = snapshot.data!.docs;

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: comments.length,
                    itemBuilder: (context, index) {
                      final commentData =
                          comments[index].data() as Map<String, dynamic>;

                      final userName = commentData['userName'] ?? "User";
                      final text = commentData['text'] ?? "";

                      return Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                            vertical: 4,
                            horizontal: 0,
                          ),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                userName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                text,
                                style: const TextStyle(color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),

              // Add new comment input
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        decoration: InputDecoration(
                          hintText: "Write a comment...",

                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send, color: Colors.orange),
                      onPressed: () async {
                        final user = FirebaseAuth.instance.currentUser;
                        if (user == null || _commentController.text.isEmpty)
                          return;

                        await FirebaseFirestore.instance
                            .collection('products')
                            .doc(widget.product.id)
                            .collection('comments')
                            .add({
                              "userId": user.uid,
                              "userName": user.displayName ?? "Anonymous",
                              "text": _commentController.text.trim(),
                              "createdAt": FieldValue.serverTimestamp(),
                            });

                        _commentController.clear();
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              //ADD TO CART
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: addToCart,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: navy,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'Add To Cart x$quantity',
                    style: TextStyle(fontSize: 18, color: orange),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
