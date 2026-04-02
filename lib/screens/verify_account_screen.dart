import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class VerifyAccountScreen extends StatefulWidget {
  const VerifyAccountScreen({Key? key}) : super(key: key);

  @override
  State<VerifyAccountScreen> createState() => _VerifyAccountScreenState();
}

class _VerifyAccountScreenState extends State<VerifyAccountScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _accountNameController = TextEditingController();
  final TextEditingController _accountNumberController =
      TextEditingController();
  final TextEditingController _bankNameController = TextEditingController();

  bool _isLoading = false;
  bool _hasAccount = false;
  bool _isEditing = false;

  Map<String, dynamic>? _currentAccount;

  @override
  void initState() {
    super.initState();
    _fetchAccountDetails();
  }

  Future<void> _fetchAccountDetails() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final doc = await _firestore.collection('sellers').doc(user.uid).get();
    if (doc.exists) {
      final data = doc.data();
      if (data != null && data['account'] != null) {
        setState(() {
          _currentAccount = data['account'];
          _hasAccount = true;
          _isEditing = false;
          _accountNameController.text = _currentAccount!['accountName'] ?? '';
          _accountNumberController.text =
              _currentAccount!['accountNumber'] ?? '';
          _bankNameController.text = _currentAccount!['bankName'] ?? '';
        });
      }
    }
  }

  Future<void> _saveAccount() async {
    if (!_formKey.currentState!.validate()) return;

    final user = _auth.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    final accountData = {
      'accountName': _accountNameController.text.trim(),
      'accountNumber': _accountNumberController.text.trim(),
      'bankName': _bankNameController.text.trim(),
      'verified': true,
    };

    try {
      await _firestore.collection('sellers').doc(user.uid).update({
        'account': accountData,
      });

      setState(() {
        _currentAccount = accountData;
        _hasAccount = true;
        _isEditing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account details saved successfully!')),
      );
    } catch (e) {
      debugPrint('Error saving account: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to save account.')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _enableEditing() {
    setState(() {
      _isEditing = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    const kCardColor = Color(0xFF0D1B2A);
    const kBackgroundColor = Color.fromARGB(255, 235, 137, 8);
    const kTextColor = Colors.orange;

    return Scaffold(
      backgroundColor: kCardColor,
      appBar: AppBar(
        backgroundColor: kCardColor,
        iconTheme: const IconThemeData(color: kBackgroundColor),
        title: const Text(
          'Verify Account',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _hasAccount && !_isEditing
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Verified Account:',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    color: kCardColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Account Name: ${_currentAccount!['accountName']}',
                                  style: const TextStyle(
                                    color: kTextColor,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  'Account Number: ${_currentAccount!['accountNumber']}',
                                  style: const TextStyle(
                                    color: kTextColor,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  'Bank: ${_currentAccount!['bankName']}',
                                  style: const TextStyle(
                                    color: kTextColor,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            children: [
                              Icon(
                                Icons.verified,
                                color: Colors.greenAccent,
                                size: 28,
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: kBackgroundColor,
                                ),
                                onPressed: _enableEditing,
                                child: const Text(
                                  'Change',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            : Form(
                key: _formKey,
                child: ListView(
                  children: [
                    TextFormField(
                      controller: _accountNameController,
                      style: const TextStyle(color: Colors.white),
                      readOnly: !_isEditing && _hasAccount,
                      decoration: InputDecoration(
                        labelText: 'Account Name',
                        labelStyle: const TextStyle(color: Colors.white70),
                        enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: kTextColor),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: kBackgroundColor),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Enter account name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _accountNumberController,
                      style: const TextStyle(color: Colors.white),
                      readOnly: !_isEditing && _hasAccount,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Account Number',
                        labelStyle: const TextStyle(color: Colors.white70),
                        enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: kTextColor),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: kBackgroundColor),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Enter account number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _bankNameController,
                      style: const TextStyle(color: Colors.white),
                      readOnly: !_isEditing && _hasAccount,
                      decoration: InputDecoration(
                        labelText: 'Bank Name',
                        labelStyle: const TextStyle(color: Colors.white70),
                        enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: kTextColor),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: kBackgroundColor),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Enter bank name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kBackgroundColor,
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _saveAccount,
                      child: const Text(
                        'Save Account',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
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
