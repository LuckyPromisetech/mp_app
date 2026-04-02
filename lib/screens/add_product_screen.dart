import 'dart:typed_data';
import 'dart:io' show File;
import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

// Import your real PromoteProductScreen
import 'promote_product_screen.dart'; // <-- update path if needed

class AddProductScreen extends StatefulWidget {
  final Map<String, dynamic>? product;

  const AddProductScreen({Key? key, this.product}) : super(key: key);

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _weightController = TextEditingController(); // NEW

  List<XFile> _pickedImages = [];
  List<Uint8List> _pickedImagesBytes = [];
  List<String> _existingImages = [];
  List<bool> _imageTooLargeFlags = [];

  bool _isLoading = false;
  int _stockQuantity = 1;

  String? _selectedCondition;
  String? _selectedCategory;
  String? _selectedCategoryId;

  static const kAccentColor = Color(0xFFFF8C00);
  static const kCardColor = Color(0xFF0D1B2A);
  static const int maxImageSizeInBytes = 5 * 1024 * 1024;

  final List<String> _conditions = ["New", "UK Used", "Local Used"];
  List<Map<String, String>> _categories = [];

  @override
  void initState() {
    super.initState();
    _fetchCategories();

    if (widget.product != null) {
      _titleController.text = widget.product!['title'] ?? '';
      _descriptionController.text = widget.product!['description'] ?? '';
      _priceController.text = widget.product!['price']?.toString() ?? '';
      _weightController.text =
          widget.product!['weight']?.toString() ?? ''; // NEW
      _stockQuantity = widget.product!['quantity'] ?? 1;
      _selectedCondition = _conditions.contains(widget.product!['condition'])
          ? widget.product!['condition']
          : _conditions[0];
      _selectedCategory = widget.product!['category'];
      _selectedCategoryId = widget.product!['categoryId'];
      if (widget.product!['images'] != null) {
        _existingImages = List<String>.from(widget.product!['images'] ?? [])
            .where((img) => img != null && img.toString().isNotEmpty)
            .map((e) => e.toString())
            .toList();
      }
    } else {
      _selectedCondition = _conditions[0];
    }
  }

  Future<void> _fetchCategories() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('categories')
        .get();

    setState(() {
      _categories = snapshot.docs
          .map((doc) => {"id": doc.id, "name": doc['name'].toString()})
          .toList();

      if (_categories.isNotEmpty) {
        _selectedCategoryId ??= _categories[0]['id'];
        _selectedCategory ??= _categories[0]['name'];
      }
    });
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final images = await picker.pickMultiImage();

    if (images.isNotEmpty) {
      _pickedImages.addAll(images);

      if (kIsWeb) {
        for (var img in images) {
          final bytes = await img.readAsBytes();
          _pickedImagesBytes.add(bytes);
          _imageTooLargeFlags.add(bytes.length > maxImageSizeInBytes);
        }
      } else {
        for (var img in images) {
          final file = File(img.path);
          _imageTooLargeFlags.add(file.lengthSync() > maxImageSizeInBytes);
        }
      }

      setState(() {});
    }
  }

  void _removeNewImage(int index) {
    _pickedImages.removeAt(index);
    if (kIsWeb) _pickedImagesBytes.removeAt(index);
    _imageTooLargeFlags.removeAt(index);
    setState(() {});
  }

  void _removeExistingImage(int index) {
    _existingImages.removeAt(index);
    setState(() {});
  }

  Future<void> _addOrUpdateProduct() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (_imageTooLargeFlags.contains(true)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "One or more images are too large. Max allowed size is 5 MB.",
          ),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      List<String> imageUrls = [];

      for (var img in _pickedImages) {
        final bytes = await img.readAsBytes();

        var request = http.MultipartRequest(
          'POST',
          Uri.parse('https://api.cloudinary.com/v1_1/dvmnhsx8r/image/upload'),
        );

        request.fields['upload_preset'] = 'BazEdge';

        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            bytes,
            filename: 'image_${DateTime.now().millisecondsSinceEpoch}.jpg',
          ),
        );

        var response = await request.send();
        var res = await http.Response.fromStream(response);

        var data = jsonDecode(res.body);
        imageUrls.add(data['secure_url']);
      }

      imageUrls.addAll(_existingImages.where((img) => img.isNotEmpty));

      final productData = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'price': double.tryParse(_priceController.text.trim()) ?? 0,
        'weight': double.tryParse(_weightController.text.trim()) ?? 1,
        'images': imageUrls,
        'quantity': _stockQuantity,
        'condition': _selectedCondition,
        'category': _selectedCategory,
        'categoryId': _selectedCategoryId,
      };

      if (widget.product != null && widget.product!['id'] != null) {
        productData['updatedAt'] = Timestamp.now();

        await FirebaseFirestore.instance
            .collection('products')
            .doc(widget.product!['id'])
            .update(productData);
      } else {
        productData['sellerId'] = user.uid;
        productData['createdAt'] = Timestamp.now();

        await FirebaseFirestore.instance
            .collection('products')
            .add(productData);
      }

      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kCardColor,
      appBar: AppBar(
        backgroundColor: kCardColor,
        iconTheme: const IconThemeData(color: kAccentColor),
        title: Text(
          widget.product != null ? 'Edit Product' : 'Add Product',
          style: const TextStyle(
            color: kAccentColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          GestureDetector(
            onTap: () {},
            child: Container(
              margin: const EdgeInsets.symmetric(
                vertical: 10.0,
                horizontal: 12.0,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: 6.0,
              ),
              decoration: BoxDecoration(
                color: kAccentColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Center(
                child: Text(
                  'Promote',
                  style: TextStyle(
                    color: Color(0xFF0D1B2A),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: kCardColor,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: _pickImages,
                        child: Container(
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.white10,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: kAccentColor, width: 1.5),
                          ),
                          child: const Center(
                            child: Text(
                              "Tap to Upload Product Images",
                              style: TextStyle(
                                color: kAccentColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      _buildImagePreview(),
                      const SizedBox(height: 25),
                      _buildField(_titleController, "Product Title"),
                      const SizedBox(height: 18),
                      _buildField(
                        _descriptionController,
                        "Product Description",
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Enter product description";
                          }
                          final pattern = RegExp(
                            r"(https?:\/\/|www\.|\.com|\.ng|wa\.me|whatsapp|t\.me|\+234\d{10}|0\d{10})",
                            caseSensitive: false,
                          );
                          if (pattern.hasMatch(value)) {
                            return "No links or contact info allowed";
                          }
                          return null;
                        },
                      ),
                      const Text(
                        "Be aware that charges of 7.5% will be applied",
                        style: TextStyle(
                          color: kAccentColor,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      _buildField(
                        _priceController,
                        "Product Price",
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 18),
                      _buildField(
                        _weightController,
                        "Product Weight (kg)",
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        "Stock Quantity",
                        style: TextStyle(color: kAccentColor),
                      ),
                      Row(
                        children: [
                          IconButton(
                            onPressed: () {
                              if (_stockQuantity > 1) {
                                setState(() => _stockQuantity--);
                              }
                            },
                            icon: const Icon(
                              Icons.remove_circle,
                              color: kAccentColor,
                            ),
                          ),
                          Text(
                            _stockQuantity.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                            ),
                          ),
                          IconButton(
                            onPressed: () => setState(() => _stockQuantity++),
                            icon: const Icon(
                              Icons.add_circle,
                              color: kAccentColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildDropdown(
                        "Product Condition",
                        _conditions,
                        _selectedCondition!,
                        (value) {
                          setState(() => _selectedCondition = value);
                        },
                      ),
                      const SizedBox(height: 20),
                      _buildDropdownCategory(),
                      const SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kAccentColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: _isLoading ? null : _addOrUpdateProduct,
                          child: _isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : Text(
                                  widget.product != null
                                      ? "Update Product"
                                      : "Add Product",
                                  style: const TextStyle(
                                    color: kCardColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownCategory() {
    return DropdownButtonFormField<String>(
      value: _selectedCategoryId,
      dropdownColor: kCardColor,
      decoration: InputDecoration(
        labelText: "Category",
        labelStyle: const TextStyle(color: kAccentColor),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: kAccentColor),
        ),
      ),
      items: _categories.map((cat) {
        return DropdownMenuItem<String>(
          value: cat['id'],
          child: Text(
            cat['name']!,
            style: const TextStyle(color: Colors.white),
          ),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedCategoryId = value;
          _selectedCategory = _categories.firstWhere(
            (cat) => cat['id'] == value,
          )['name'];
        });
      },
      validator: (value) => value == null ? "Select Category" : null,
    );
  }

  Widget _buildImagePreview() {
    List<Widget> imageTiles = [];

    /// EXISTING IMAGES (from database)
    for (int i = 0; i < _existingImages.length; i++) {
      imageTiles.add(
        Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Image.network(
                _existingImages[i],
                width: 100,
                height: 100,
                fit: BoxFit.cover,
              ),
            ),
            Positioned(
              top: 5,
              right: 5,
              child: GestureDetector(
                onTap: () => _removeExistingImage(i),
                child: const CircleAvatar(
                  radius: 12,
                  backgroundColor: Colors.red,
                  child: Icon(Icons.close, size: 14, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      );
    }

    /// NEW PICKED IMAGES (FIXED + REMOVE BUTTON)
    for (int i = 0; i < _pickedImages.length; i++) {
      imageTiles.add(
        Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: kIsWeb
                  ? Image.memory(
                      _pickedImagesBytes[i],
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    )
                  : Image.file(
                      File(_pickedImages[i].path),
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 100,
                          height: 100,
                          color: Colors.grey,
                          child: const Icon(
                            Icons.broken_image,
                            color: Colors.white,
                          ),
                        );
                      },
                    ),
            ),

            /// ❌ REMOVE BUTTON (NEW IMAGES)
            Positioned(
              top: 5,
              right: 5,
              child: GestureDetector(
                onTap: () => _removeNewImage(i),
                child: const CircleAvatar(
                  radius: 12,
                  backgroundColor: Colors.red,
                  child: Icon(Icons.close, size: 14, color: Colors.white),
                ),
              ),
            ),

            /// ⚠️ LARGE IMAGE WARNING
            if (_imageTooLargeFlags.length > i && _imageTooLargeFlags[i])
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  color: Colors.red.withOpacity(0.7),
                  padding: const EdgeInsets.all(2),
                  child: const Text(
                    "Too Large",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 10, color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
      );
    }

    return Wrap(spacing: 10, runSpacing: 10, children: imageTiles);
  }

  Widget _buildField(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: kAccentColor),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: kAccentColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: kAccentColor, width: 2),
        ),
      ),
      validator:
          validator ??
          (value) => value == null || value.isEmpty ? 'Enter $label' : null,
    );
  }

  Widget _buildDropdown(
    String label,
    List<String> items,
    String selectedValue,
    Function(String?) onChanged,
  ) {
    return DropdownButtonFormField<String>(
      value: selectedValue,
      dropdownColor: kCardColor,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: kAccentColor),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: kAccentColor),
        ),
      ),
      items: items
          .map(
            (item) => DropdownMenuItem(
              value: item,
              child: Text(item, style: const TextStyle(color: Colors.white)),
            ),
          )
          .toList(),
      onChanged: onChanged,
      validator: (value) => value == null ? "Select $label" : null,
    );
  }
}
