import 'package:cashit/backend/firebase_auth_service.dart';
import 'package:cashit/classes/colors.dart';
import 'package:cashit/widget/toast.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pinput/pinput.dart';

class CreatePinPage extends StatefulWidget {
  const CreatePinPage({super.key});

  @override
  State<CreatePinPage> createState() => _CreatePinPageState();
}

class _CreatePinPageState extends State<CreatePinPage> {
  final _pinController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _authService = FirebaseAuthService();
  bool _isLoading = false;

  static const pastelGreen = ColorPalletes.pastelGreen;
  static const pastelpurple = ColorPalletes.pastelpurple;
  static const pastelPink = ColorPalletes.pastelPink;

  Future<void> _savePin() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final pin = _pinController.text;
      final success = await _authService.createPin(pin);

      if (success && mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      } else if (mounted) {
        showToast(message: "Failed to save PIN. Please try again.");
      }
    } catch (e) {
      if (mounted) {
        showToast(message: "An error occurred: ${e.toString()}");
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final defaultPinTheme = PinTheme(
      width: 56,
      height: 60,
      textStyle: GoogleFonts.poppins(fontSize: 22, color: Colors.black),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(width: 2, color: Colors.grey.shade400)),
      ),
    );

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: 500
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        body: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(30.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Create PIN',
                        style: GoogleFonts.poppins(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Please do not use your birthdate as your PIN number',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.pink[300],
                        ),
                      ),
                      const SizedBox(height: 60),
                      Pinput(
                        controller: _pinController,
                        length: 6,
                        obscureText: true,
                        defaultPinTheme: defaultPinTheme,
                        focusedPinTheme: defaultPinTheme.copyWith(
                          decoration: defaultPinTheme.decoration!.copyWith(
                            border: Border(bottom: BorderSide(width: 2, color: pastelpurple)),
                          ),
                        ),
                        submittedPinTheme: defaultPinTheme.copyWith(
                          decoration: defaultPinTheme.decoration!.copyWith(
                            border: Border(bottom: BorderSide(width: 2, color: pastelGreen)),
                          ),
                        ),
                        validator: (s) {
                          return s?.length == 6 ? null : 'PIN must be 6 digits';
                        },
                      ),
                    ],
                  ),
                ),
              ),
              
              Padding(
                padding: const EdgeInsets.all(30.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 15),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.black),
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [pastelGreen, pastelpurple, pastelPink],
                            stops: [0.3, 0.75, 1.0],
                          ),
                        ),
                        child: InkWell(
                          onTap: _isLoading ? null : _savePin,
                          child: _isLoading
                          ? const Center(child: CircularProgressIndicator(color: Colors.black))
                          : Text(
                            'Continue',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              color: Colors.black,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
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
        ),
      ),
    );
  }
}