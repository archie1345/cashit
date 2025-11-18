import 'dart:convert';
import 'package:cashit/backend/firebase_auth_service.dart';
import 'package:cashit/classes/colors.dart';
import 'package:cashit/page/successAddBalance.dart';
import 'package:cashit/widget/toast.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Addbalancepage extends StatefulWidget {
  const Addbalancepage({super.key});

  @override
  State<Addbalancepage> createState() => _AddbalancepageState();
}

class _AddbalancepageState extends State<Addbalancepage> {
  final _amountController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  static const pastelGreen = ColorPalletes.pastelGreen;
  static const pastelpurple = ColorPalletes.pastelpurple;
  static const pastelPink = ColorPalletes.pastelPink;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _handleTopUp() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    setState(() {
      _isLoading = true;
    });

    try {
      final amount = 10000;
      if (amount <= 0) {
        showToast(message: 'Please enter a valid amount');
        return;
      }

      if (kIsWeb) {
        await _handleWebCheckout(amount);
      } else {
        await _handleMobileCheckout(amount);
      }
    } catch (e) {
      if (mounted) {
        showToast(message: 'Error: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleWebCheckout(int amount) async {
    try {
      final clientSecret = await _createWebCheckoutSession(amount);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('pending_topup_amount', amount);
      
      await launchUrl(Uri.parse(clientSecret));
      
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      showToast(message: 'Error: ${e.toString()}');
    }
  }

  Future<String> _createWebCheckoutSession(int amount) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not logged in.');
    }
    final idToken = await user.getIdToken(true);

    final response = await http.post(
      Uri.parse('$baseUrl/api/create-checkout-session'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: jsonEncode({'amount': amount}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['checkoutUrl'];
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(
          'Failed to create checkout session: ${errorData['error']}');
    }
  }

  Future<void> _handleMobileCheckout(int amount) async {
    try {
      final clientSecret = await _createMobilePaymentIntent(amount);

      await _presentMobilePaymentSheet(clientSecret, amount);
    } catch (e) {
      rethrow;
    }
  }

  Future<String> _createMobilePaymentIntent(int amount) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not logged in.');
    }
    final idToken = await user.getIdToken(true);

    final response = await http.post(
      Uri.parse('$baseUrl/api/create-top-up-intent'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: jsonEncode({'amount': amount}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['clientSecret'];
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception('Failed to create payment intent: ${errorData['error']}');
    }
  }

  Future<void> _presentMobilePaymentSheet(String clientSecret, int amount) async {
    try {
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'CashIt',
          style: ThemeMode.light,
        ),
      );

      await Stripe.instance.presentPaymentSheet();

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => TopUpSuccessPage(
              amount: amount,
              transactionDate: DateTime.now(),
            ),
          ),
        );
      }
    } on StripeException catch (e) {
      if (e.error.code == FailureCode.Canceled) {
        showToast(message: 'Payment canceled');
      } else {
        showToast(message: 'Payment failed: ${e.error.message}');
      }
    } catch (e) {
      showToast(message: 'An unexpected error occurred: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Top Up', style: GoogleFonts.poppins()),
        backgroundColor: pastelpurple.withOpacity(0.8),
      ),
      backgroundColor: Colors.white,
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Amount',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _amountController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: false),
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        prefixText: 'Rp ',
                        hintText: '0',
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter an amount';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 30),
                    Text(
                      'Payment Method',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ListTile(
                        leading: Icon(Icons.credit_card, color: pastelpurple),
                        title: Text('Debit/Credit Card',
                            style: GoogleFonts.poppins()),
                        subtitle: Text('Powered by Stripe',
                            style: GoogleFonts.poppins(fontSize: 12)),
                        trailing: Icon(Icons.check_circle, color: Colors.green),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: _isLoading ? null : _handleTopUp,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'Top up',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
