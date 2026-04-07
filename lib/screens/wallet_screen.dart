import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http; // <-- Add this import
import 'verify_account_screen.dart';

class WalletScreen extends StatefulWidget {
  @override
  _WalletScreenState createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  double balance = 0;
  double pending = 0;

  final TextEditingController amountController = TextEditingController();
  Map<String, dynamic>? account;
  bool isLoadingAccount = true;

  List<Map<String, dynamic>> transactions = [];

  @override
  void initState() {
    super.initState();
    fetchWalletData();
  }

  Future<void> fetchWalletData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('sellers')
        .doc(user.uid)
        .get();

    if (doc.exists) {
      final data = doc.data();
      setState(() {
        balance = data?['wallet']['balance']?.toDouble() ?? 0;
        pending = data?['wallet']['pending']?.toDouble() ?? 0;
        account = data?['account'];
        transactions = List<Map<String, dynamic>>.from(
          data?['transactions'] ?? [],
        );
        isLoadingAccount = false;
      });
    }
  }

  Future<void> callPayoutBackend(double amount) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final url = Uri.parse(
      'https://your-backend-url/payout',
    ); // <-- Replace with your backend
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'sellerId': user.uid,
          'amount': amount,
          'orderId': 'manual-withdraw-${DateTime.now().millisecondsSinceEpoch}',
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['status'] == 'success') {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Withdrawal successful!")));
        fetchWalletData(); // Refresh wallet data
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Withdrawal failed: ${data['message'] ?? 'Unknown error'}",
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  void handleWithdraw() {
    double amount = double.tryParse(amountController.text) ?? 0;

    if (amount <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Enter valid amount")));
      return;
    }

    if (amount > balance) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Insufficient balance")));
      return;
    }

    if (account == null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VerifyAccountScreen(isWithdraw: true, amount: amount),
        ),
      );
      return;
    }

    // ✅ Call backend payout
    callPayoutBackend(amount);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0D1B2A),
      appBar: AppBar(title: Text("Wallet"), backgroundColor: Color(0xFF0A1931)),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // 🔥 WALLET CARD
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.orange, Color(0xFFFF8C42)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Available Balance",
                    style: TextStyle(color: Colors.white70),
                  ),
                  SizedBox(height: 5),
                  Text(
                    "₦$balance",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    "Incoming (Pending)",
                    style: TextStyle(color: Colors.white70),
                  ),
                  SizedBox(height: 5),
                  Text(
                    "₦$pending",
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ],
              ),
            ),

            SizedBox(height: 20),

            // 🏦 ACCOUNT DISPLAY
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: isLoadingAccount
                  ? Center(child: CircularProgressIndicator())
                  : account == null
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "No bank account added",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 10),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => VerifyAccountScreen(),
                              ),
                            );
                          },
                          child: Text("Add Account"),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Withdrawal Account",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 10),
                        Text("Name: ${account!['accountName']}"),
                        Text("Number: ${account!['accountNumber']}"),
                        Text("Bank: ${account!['bankName']}"),
                        SizedBox(height: 10),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => VerifyAccountScreen(),
                              ),
                            );
                          },
                          child: Text("Change Account"),
                        ),
                      ],
                    ),
            ),

            SizedBox(height: 20),

            // 💰 AMOUNT INPUT
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Enter amount to withdraw",
                prefixText: "₦ ",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            SizedBox(height: 20),

            // 💸 WITHDRAW BUTTON
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: handleWithdraw,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF0A1931),
                  padding: EdgeInsets.symmetric(vertical: 15),
                ),
                child: Text(
                  "Withdraw Money",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),

            SizedBox(height: 20),

            // 📄 HISTORY TITLE
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Transaction History",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                  fontSize: 16,
                ),
              ),
            ),

            SizedBox(height: 10),

            // 📜 TRANSACTIONS
            Expanded(
              child: transactions.isEmpty
                  ? Center(
                      child: Text(
                        "No transactions yet",
                        style: TextStyle(color: Colors.white70),
                      ),
                    )
                  : ListView.builder(
                      itemCount: transactions.length,
                      itemBuilder: (context, index) {
                        final tx = transactions[index];
                        final color = tx['type'] == 'debit'
                            ? Colors.red
                            : Colors.green;
                        final amountSign = tx['type'] == 'debit' ? '-' : '+';
                        return _buildTransaction(
                          tx['title'],
                          "$amountSign₦${tx['amount']}",
                          color,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransaction(String title, String amount, Color color) {
    return Container(
      margin: EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title),
          Text(
            amount,
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
