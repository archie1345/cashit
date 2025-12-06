import 'dart:convert';
import 'package:cashit/backend/firebase_auth_service.dart';
import 'package:cashit/page/transactionStatus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class TopUpPage extends StatefulWidget {
  final String title;
  final IconData icon;
  final Color color;
  final Color iconColor;
  final String inputLabel;
  final String placeholder;
  final String billerStripeId;
  final String billType;
  
  const TopUpPage({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.iconColor,
    required this.inputLabel,
    required this.billerStripeId,
    required this.billType,
    this.placeholder = 'Enter ID Number',
    });

  @override
  State<TopUpPage> createState() => _TopUpPageState();
}

class _TopUpPageState extends State<TopUpPage> {
  final _customerIdController = TextEditingController(); // Renamed from meterController
  final _amountController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  bool _isLoading = false;

  @override
  void dispose() {
    _customerIdController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  int _getCleanAmount(String value) {
    String clean = value.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(clean) ?? 0;
  }

  Future<void> _handleConfirmPayment() async {
    if (_formKey.currentState!.validate()) {
      
      final result = await Navigator.pushNamed(context, '/enterPin');

      if (result != null && result is String && result.isNotEmpty) {
        _processPayment(result);
      }
    }
  }

  Future<void> _processPayment(String pin) async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not logged in");

      final idToken = await user.getIdToken();
      final amount = _getCleanAmount(_amountController.text);
      final customerId = _customerIdController.text.trim();
      
      final response = await http.post(
        Uri.parse('$baseUrl/api/pay-bill'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode({
          'amount': amount,
          'billerAccountId': widget.billerStripeId,
          'accountNumber': customerId,
          'pin': pin,
          'billType': widget.billType,
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => TransactionstatusPage(
                isSuccess: true,
                type: TransactionType.transfer,
                amount: amount,
                transactionDate: DateTime.now(),
                serviceName: widget.title,
              ),
            ),
          );
        }
      } else {
        throw Exception(responseData['error'] ?? 'Payment failed');
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed: ${e.toString().replaceAll('Exception:', '')}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade200, Colors.purple.shade200],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black87),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text(
                      widget.title, // Dynamic Title
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.black87),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: widget.color, // Dynamic Color
                            shape: BoxShape.circle,
                          ),
                          child: Icon(widget.icon, size: 50, color: widget.iconColor), // Dynamic Icon
                        ),
                      ),
                      const SizedBox(height: 30),

                      Text(widget.inputLabel, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _customerIdController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: widget.placeholder, // Dynamic Placeholder
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                      ),
                      
                      const SizedBox(height: 20),

                      Text('Amount', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          CurrencyInputFormatter()
                        ],
                        decoration: InputDecoration(
                          hintText: '\$0.00',
                          prefixText: '', 
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        validator: (value) {
                          if (_getCleanAmount(value!) <= 0) return 'Enter valid amount';
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleConfirmPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text('Pay Now', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue.copyWith(text: '');
    String newText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    double value = double.tryParse(newText) ?? 0;
    final formatter = NumberFormat.currency(locale: 'en_US', symbol: '\$');
    String newString = formatter.format(value / 100);
    return newValue.copyWith(text: newString, selection: TextSelection.collapsed(offset: newString.length));
  }
}