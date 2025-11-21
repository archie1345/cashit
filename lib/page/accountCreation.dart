import 'dart:async';
import 'package:cashit/backend/firebase_auth_service.dart';
import 'package:cashit/classes/RegistrationData.dart';
import 'package:cashit/classes/colors.dart';
import 'package:cashit/widget/form_container_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';

class Accountcreation extends StatefulWidget {
  const Accountcreation({super.key});

  @override
  State<Accountcreation> createState() => _AccountcreationState();
}

class _AccountcreationState extends State<Accountcreation> {
  final _usernameController = TextEditingController();
  final _fullnameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  static const pastelGreen = ColorPalletes.pastelGreen;
  static const pastelpurple = ColorPalletes.pastelpurple;
  static const pastelPink = ColorPalletes.pastelPink;
  
  final _formKey = GlobalKey<FormState>();
  final _authService = FirebaseAuthService();
  bool isLoading = false;

  // --- Username Check State ---
  Timer? _debounce;
  String? _usernameStatusText;
  Color _usernameStatusColor = Colors.grey;
  bool _isUsernameAvailable = false;
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    _usernameController.addListener(_onUsernameChanged);
  }

  @override
  void dispose() {
    _usernameController.removeListener(_onUsernameChanged);
    _usernameController.dispose();
    _fullnameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onUsernameChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    
    setState(() {
      _usernameStatusText = null;
      _isUsernameAvailable = false;
    });

    final username = _usernameController.text.trim();
    if (username.isEmpty) return;

    // Wait 500ms after user stops typing before checking DB
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _checkUsername(username);
    });
  }

  Future<void> _checkUsername(String username) async {
    setState(() {
      _isChecking = true;
      _usernameStatusText = "Checking availability...";
      _usernameStatusColor = Colors.blue;
    });

    bool available = await _authService.isUsernameAvailable(username);

    if (mounted) {
      setState(() {
        _isChecking = false;
        _isUsernameAvailable = available;
        if (available) {
          _usernameStatusText = "Username is available";
          _usernameStatusColor = Colors.green;
        } else {
          _usernameStatusText = "Username is already taken";
          _usernameStatusColor = Colors.red;
        }
      });
    }
  }

  Future<void> _register(RegistrationData data) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (!_isUsernameAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please choose a valid available username')),
      );
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password and Confirm Password do not match')),
      );
      return;
    }

    setState(() => isLoading = true);

    final user = await _authService.signUpWithEmailAndPassword(
      data.email,
      _passwordController.text.trim(),
      _usernameController.text.trim().toLowerCase(),
      _fullnameController.text.trim(),
      data.idNum,
      data.birthLoc,
      data.birthDate,
      data.address,
      data.reason,
    );

    if (mounted) setState(() => isLoading = false);

    if (user != null && mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/create_pin', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final RegistrationData registrationData = ModalRoute.of(context)!.settings.arguments as RegistrationData;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        Navigator.pop(context);
      },
      child: Center(
        child: Scaffold(
          body: Stack(
            children: [
              Container(color: Colors.white),
              SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: AppBar(
                          backgroundColor: Colors.transparent,
                          automaticallyImplyLeading: false,
                          title: Center(
                            child: Text(
                              'Create Your Account',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        child: Container(
                          width: 400,
                          decoration: BoxDecoration(borderRadius: BorderRadius.circular(15)),
                          child: Column(
                            children: [
                              SvgPicture.asset('assets/logo.svg'),
                              Text(
                                'CashIt',
                                style: GoogleFonts.inter(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              
                              // --- USERNAME FIELD & STATUS ---
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    FormContainerWidget(
                                      title: 'Username',
                                      iconPath: 'assets/IdentificationCard.svg',
                                      helperText: 'Enter your username',
                                      hintText: 'Enter your username',
                                      controller: _usernameController,
                                      inputType: TextInputType.text,
                                    ),
                                    if (_usernameStatusText != null)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 5, left: 5),
                                        child: Row(
                                          children: [
                                            if (_isChecking) 
                                              Container(
                                                width: 12, height: 12, 
                                                margin: const EdgeInsets.only(right: 8),
                                                child: const CircularProgressIndicator(strokeWidth: 2)
                                              ),
                                            Text(
                                              _usernameStatusText!,
                                              style: TextStyle(
                                                color: _usernameStatusColor,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              // -------------------------------

                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                                child: FormContainerWidget(
                                  title: 'Full Name',
                                  iconPath: 'assets/IdentificationCard.svg',
                                  helperText: 'Enter your Full Name',
                                  hintText: 'Enter your Full Name',
                                  controller: _fullnameController,
                                  inputType: TextInputType.text,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                                child: FormContainerWidget(
                                  title: 'Password',
                                  iconPath: 'assets/lock.svg',
                                  helperText: 'Enter your Password',
                                  hintText: 'Enter your password',
                                  controller: _passwordController,
                                  isPasswordField: true,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                                child: FormContainerWidget(
                                  title: 'Confirm Password',
                                  iconPath: 'assets/lock.svg',
                                  helperText: 'confirm your password',
                                  hintText: 'confirm your password',
                                  controller: _confirmPasswordController,
                                  isPasswordField: true,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 50.0, left: 20, right: 20),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(vertical: 15),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(color: Colors.black),
                                          gradient: const LinearGradient(
                                            begin: Alignment.centerLeft,
                                            end: Alignment.centerRight,
                                            colors: [pastelGreen, pastelpurple, pastelPink],
                                            stops: [0.3, 0.75, 1.0],
                                          ),
                                        ),
                                        child: InkWell(
                                          // Disable button if loading OR username is invalid
                                          onTap: (isLoading || (_usernameController.text.isNotEmpty && !_isUsernameAvailable)) 
                                              ? null 
                                              : () => _register(registrationData),
                                          child: isLoading
                                              ? const Center(child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.black)))
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
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}