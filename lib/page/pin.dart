import 'package:cashit/backend/firebase_auth_service.dart';
import 'package:cashit/classes/colors.dart';
import 'package:cashit/widget/toast.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';

class PinPage extends StatefulWidget {
  const PinPage({Key? key}) : super(key: key);

  @override
  State<PinPage> createState() => _PinPageState();
}

class _PinPageState extends State<PinPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _currentController = TextEditingController();
  final TextEditingController _newController = TextEditingController();
  final FirebaseAuthService _authService = FirebaseAuthService();
  bool _isSaving = false;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    super.dispose();
  }

  Future<void> _savePin() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final current = _currentController.text.trim();
    final next = _newController.text.trim();

    if (current == next) {
      showToast(message: 'New PIN must be different from current PIN');
      return;
    }

    setState(() => _isSaving = true);
    try {
      final success = await _authService.createPin(next);
      if (success && mounted) {
        showToast(message: 'PIN updated');
        Navigator.maybePop(context);
      } else if (mounted) {
        showToast(message: 'Failed to save PIN. Please try again.');
      }
    } catch (e) {
      showToast(message: 'An error occurred: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pastelGreen = ColorPalletes.pastelGreen;
    final pastelPurple = ColorPalletes.pastelpurple;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 500),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              // Header gradient with back button
              Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [pastelGreen, pastelPurple],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.maybePop(context),
                  ),
                ),
              ),

              // Content card
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 18),
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Current PIN',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _currentController,
                                  obscureText: true,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  maxLength: 6,
                                  decoration: InputDecoration(
                                    counterText: '',
                                    hintText: 'Current PIN',
                                    filled: true,
                                    fillColor: const Color(0xFFF3F3F5),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: Colors.black38,
                                        width: 1,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: Colors.black54,
                                        width: 1,
                                      ),
                                    ),
                                  ),
                                  validator: (s) => (s != null && s.length == 6)
                                      ? null
                                      : 'PIN must be 6 digits',
                                ),

                                const SizedBox(height: 16),
                                Text(
                                  'New PIN',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _newController,
                                  obscureText: true,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  maxLength: 6,
                                  decoration: InputDecoration(
                                    counterText: '',
                                    hintText: 'New PIN',
                                    filled: true,
                                    fillColor: const Color(0xFFF3F3F5),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: Colors.black38,
                                        width: 1,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: Colors.black54,
                                        width: 1,
                                      ),
                                    ),
                                  ),
                                  validator: (s) => (s != null && s.length == 6)
                                      ? null
                                      : 'PIN must be 6 digits',
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Spacer(),

                        // Confirm button
                        Padding(
                          padding: const EdgeInsets.only(bottom: 20.0),
                          child: SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _isSaving ? null : _savePin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(28),
                                ),
                              ),
                              child: _isSaving
                                  ? const CircularProgressIndicator(
                                      color: Colors.white,
                                    )
                                  : const Text(
                                      'Confirm',
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
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
