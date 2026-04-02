class Category {
  final String id;
  final String name;
  final String imageUrl;
  final bool isActive;

  Category({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.isActive,
  });

  factory Category.fromFirestore(Map<String, dynamic> data, String id) {
    return Category(
      id: id,
      name: data['name'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      isActive: data['isActive'] ?? true,
    );
  }
}
