import 'dart:async';
import 'dart:convert';
import 'package:cashit/backend/firebase_auth_service.dart';
import 'package:cashit/classes/colors.dart';
import 'package:cashit/classes/formatter.dart';
import 'package:cashit/widget/transactionStatus.dart';
import 'package:cashit/widget/toast.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
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

  bool _isAmountValid = false;
  String? _helperText = "Enter amount";
  Color _helperColor = Colors.grey;

  static const pastelGreen = ColorPalletes.pastelGreen;
  static const pastelpurple = ColorPalletes.pastelpurple;
  static const pastelPink = ColorPalletes.pastelPink;

  @override
  void initState() {
    super.initState();
    _amountController.addListener(_onAmountChanged);
  }

  @override
  void dispose() {
    _amountController.removeListener(_onAmountChanged);
    _amountController.dispose();
    super.dispose();
  }

  void _onAmountChanged() {
    _validateAmount();
  }

  void _validateAmount() {
    int cents = _getCleanAmount(_amountController.text);
    
    setState(() {
      if (cents <= 0) {
        _isAmountValid = false;
        _helperText = "Enter amount";
        _helperColor = Colors.grey;
      } else if (cents < 50) {
        _isAmountValid = false;
        _helperText = "Minimum amount is \$0.50";
        _helperColor = Colors.red;
      } else {
        _isAmountValid = true;
        _helperText = "Amount valid";
        _helperColor = Colors.green;
      }
    });
  }

  int _getCleanAmount(String value) {
    String clean = value.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(clean) ?? 0;
  }

  Future<void> _handleTopUp() async {
    if (!_isAmountValid) {
      return;
    }
    setState(() {
      _isLoading = true;
    });

    try {
      final amount = _getCleanAmount(_amountController.text);
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
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final userDocSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final int initialBalance = userDocSnapshot.data()?['balance'] ?? 0;

      final clientSecret = await _createWebCheckoutSession(amount);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('pending_topup_amount', amount);

      await launchUrl(Uri.parse(clientSecret), mode: LaunchMode.externalApplication);
      
      if (!mounted) return;

      StreamSubscription? listener;
      
      void finishTransaction() {
        listener?.cancel();
        if (mounted) {
          Navigator.of(context, rootNavigator: true).pop();
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => TransactionstatusPage(
                type: TransactionType.transfer,
                amount: amount,
                transactionDate: DateTime.now(),
              ),
            ),
          );
        }
      }

      listener = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots()
          .listen((snapshot) {
        if (!snapshot.exists) return;
        final newBalance = snapshot.data()?['balance'] ?? 0;
        
        if (newBalance > initialBalance) {
          finishTransaction();
        }
      });

      showDialog(
        context: context,
        barrierDismissible: false, 
        builder: (BuildContext context) {
          return PopScope(
            canPop: false, 
            child: AlertDialog(
              title: Text("Processing Payment", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 20),
                  const Text("Please complete the payment in the browser."),
                  const SizedBox(height: 10),
                  Text(
                    "If you closed the tab or canceled, click below.", 
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    listener?.cancel();
                    Navigator.of(context, rootNavigator: true).pop();
                    showToast(message: "Transaction processing stopped.");
                  },
                  child: Text(
                    "I Canceled / Closed Tab",
                    style: GoogleFonts.poppins(color: Colors.red),
                  ),
                ),
              ],
            ),
          );
        },
      );

    } catch (e) {
      showToast(message: 'Error: ${e.toString()}');
      if(mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<String> _createWebCheckoutSession(int amount) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not logged in.');
    final idToken = await user.getIdToken(true);

    String successUrl;
    String cancelUrl;

    if (kIsWeb) {
      successUrl = "$baseUrl/api/web-success"; 
      cancelUrl = "$baseUrl/api/web-cancel";
    } else {
      successUrl = "$baseUrl/api/checkout-success";
      cancelUrl = "$baseUrl/api/checkout-cancel";
    }

    final body = <String, dynamic>{
      'amount': amount,
      'platform': kIsWeb ? 'web' : 'mobile',
      'successUrl': successUrl,
      'cancelUrl': cancelUrl,
    };

    final response = await http.post(
      Uri.parse('$baseUrl/api/create-checkout-session'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['checkoutUrl'];
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception('Failed to create checkout session: ${errorData['error']}');
    }
  }

  Future<void> _handleMobileCheckout(int amount) async {
    try {
      final clientSecret = await _createMobilePaymentIntent(amount);
      await _presentPaymentSheet(clientSecret, amount);
    } catch (e) {
      rethrow;
    }
  }

  Future<String> _createMobilePaymentIntent(int amount) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not logged in.');
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

  Future<void> _presentPaymentSheet(String clientSecret, int amount) async {
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
    builder: (_) => TransactionstatusPage(
      type: TransactionType.transfer,
      isSuccess: true,
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
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [pastelGreen, pastelpurple, pastelPink],
                stops: [0.1, 0.5, 1.0],
              ),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.only(left: 8.0, right: 8.0, bottom: 16.0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.black87),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      Expanded(
                        child: Text(
                          'Top Up Balance',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 22, 
                            fontWeight: FontWeight.w700
                          ),
                        ),
                      ),
                      const SizedBox(width: 48), // Balance the back button
                    ],
                  ),
                ),

                Expanded(
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(top: 10),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 15,
                          offset: Offset(0, -5),
                        )
                      ],
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(30.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Amount to Add',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextFormField(
                              controller: _amountController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              inputFormatters: [
                                CurrencyInputFormatter() 
                              ],
                              style: GoogleFonts.poppins(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                              decoration: InputDecoration(
                                prefixText: '', 
                                hintText: '\$0.00', // USD Hint
                                filled: true,
                                fillColor: Colors.grey[100],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                                helperText: _helperText,
                                helperStyle: GoogleFonts.poppins(
                                  color: _helperColor,
                                  fontWeight: FontWeight.w500
                                ),
                              ),
                            ),
                            
                            const SizedBox(height: 40),
                            
                            // Payment Method Indicator
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.credit_card, color: Colors.purple),
                                  const SizedBox(width: 16),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Payment Method",
                                        style: GoogleFonts.poppins(
                                          fontSize: 12, color: Colors.grey
                                        ),
                                      ),
                                      Text(
                                        "Debit / Credit Card",
                                        style: GoogleFonts.poppins(
                                          fontSize: 16, fontWeight: FontWeight.w600
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Spacer(),
                                  const Icon(Icons.lock_outline, size: 18, color: Colors.grey),
                                ],
                              ),
                            ),

                            const SizedBox(height: 40),

                            // Submit Button
                            SizedBox(
                              width: double.infinity,
                              height: 55,
                              child: ElevatedButton(
                                onPressed: (_isLoading || !_isAmountValid) ? null : _handleTopUp,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  elevation: 0,
                                ),
                                child: _isLoading
                                    ? const CircularProgressIndicator(color: Colors.white)
                                    : Text(
                                        'Proceed to Payment',
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
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
          ),
        ],
      ),
    );
  }
}