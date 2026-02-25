import 'dart:typed_data';
import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({Key? key}) : super(key: key);

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();

  final _productNameController = TextEditingController();
  final _productCategoryController = TextEditingController();
  final _productDetailsController = TextEditingController();
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();
  final _deliveryPriceController = TextEditingController();

  XFile? _pickedImage;
  Uint8List? _pickedImageBytes;
  bool _isLoading = false;

  // PICK IMAGE
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      _pickedImage = picked;

      if (kIsWeb) {
        _pickedImageBytes = await picked.readAsBytes();
      }

      setState(() {});
    }
  }

  // ADD PRODUCT
  Future<void> _addProduct() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('You must be logged in')));
      return;
    }

    if (_pickedImage == null && _pickedImageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select product image')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1️⃣ Upload Image to Firebase Storage
      final fileName =
          'products/${user.uid}_${DateTime.now().millisecondsSinceEpoch}.png';

      final storageRef = FirebaseStorage.instance.ref().child(fileName);

      if (kIsWeb) {
        await storageRef.putData(_pickedImageBytes!);
      } else {
        await storageRef.putFile(File(_pickedImage!.path));
      }

      final imageUrl = await storageRef.getDownloadURL();

      // 2️⃣ Save Product to Firestore
      await FirebaseFirestore.instance.collection('products').add({
        'title': _productNameController.text.trim(),
        'description': _productDetailsController.text.trim(),
        'image_url': imageUrl,
        'price': double.tryParse(_priceController.text.trim()) ?? 0,
        'delivery_price':
            double.tryParse(_deliveryPriceController.text.trim()) ?? 0,
        'quantity': int.tryParse(_quantityController.text.trim()) ?? 0,
        'category': _productCategoryController.text.trim(),
        'seller_id': user.uid,
        'created_at': Timestamp.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product added successfully 🎉')),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }

    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _productNameController.dispose();
    _productCategoryController.dispose();
    _productDetailsController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _deliveryPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Product')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: kIsWeb
                        ? (_pickedImageBytes != null
                              ? MemoryImage(_pickedImageBytes!)
                              : null)
                        : (_pickedImage != null
                                  ? FileImage(File(_pickedImage!.path))
                                  : null)
                              as ImageProvider<Object>?,
                    child: _pickedImage == null && _pickedImageBytes == null
                        ? const Icon(Icons.camera_alt, size: 40)
                        : null,
                  ),
                ),

                const SizedBox(height: 20),

                TextFormField(
                  controller: _productNameController,
                  decoration: const InputDecoration(
                    labelText: 'Product Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Enter product name'
                      : null,
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _productCategoryController,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _productDetailsController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Product Details',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Enter product details'
                      : null,
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _quantityController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Quantity',
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Price',
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _deliveryPriceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Delivery Price',
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _addProduct,
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Add Product'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
