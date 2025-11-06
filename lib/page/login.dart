import 'package:cashit/backend/firebase_auth_service.dart';
import 'package:cashit/widget/colors.dart';
import 'package:cashit/widget/form_container_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';



class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  static const pastelGreen = ColorPalletes.pastelGreen;
  static const pastelpurple = ColorPalletes.pastelpurple;
  static const pastelPink = ColorPalletes.pastelPink;

  final _authService = FirebaseAuthService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _message = '';
  bool _isLoading = false;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Scaffold(
        body: Stack(
          children: [
            Container(
              color: Colors.white,
            ),
            SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsetsGeometry.symmetric(horizontal: 20,vertical: 10),
                    child: AppBar(
                      backgroundColor: Colors.transparent,
                      title: Center(
                        child: Text(
                        'Welcome Back!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w900
                        )
                        ),
                      ),)),
                      SizedBox(
                        height: 170,
                        width: 200,
                        child: Container(
                          padding: EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Column(
                            children: [
                              SvgPicture.asset('assets/logo.svg'),
                              Text(
                                'CashIt',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.black,
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 400),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            FormContainerWidget(
                              controller: _emailController,
                              hintText: 'Email',
                              labelText: 'Email',
                              iconPath: 'assets/mail.svg',
                              title: 'Email or Phone Number',
                            ),
                            const SizedBox(height: 12),
                            FormContainerWidget(
                              controller: _passwordController,
                              hintText: 'password',
                              labelText: 'password',
                              isPasswordField: true,
                              iconPath: 'assets/lock.svg',
                              title: 'Password',
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              child: Container(
                                height: 20,
                                width: double.infinity,
                                alignment: Alignment.topLeft,
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.pushNamed(
                                      context,
                                      '/forgotpassword'
                                    );
                                  },
                                  child: const Text(
                                    'Forgot Password',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 14,
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            if (_isLoading)
                              const Center(child: CircularProgressIndicator())
                            else
                              Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: 
                                          Container(
                                            padding: EdgeInsets.symmetric(vertical: 15),
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(10),
                                              border: Border.all(
                                                color: Colors.black
                                                ),
                                              gradient: LinearGradient(
                                                begin: Alignment.centerLeft,
                                                end: Alignment.centerRight,
                                                colors: [pastelGreen, pastelpurple, pastelPink],
                                                stops: [0.3, 0.75, 1.0],
                                              ),
                                            ),
                                            child: GestureDetector(
                                              onTap: _login, 
                                              child: const Text(
                                                'Login',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  color: Colors.black,
                                                  fontSize: 18,
                                                  fontFamily: 'Poppins',
                                                  fontWeight: FontWeight.w900,
                                                ),)
                                            ),
                                          )
                                        ),
                                      ],
                                    ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 20.0),
                                    child: const Text(
                                      'or sign up with',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 14,
                                        fontFamily: 'League Spartan',
                                        fontWeight: FontWeight.w300,
                                        height: 1,
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      _googleSignIn();
                                    },
                                    child: Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        color: Colors.black,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Center(
                                        child: Icon(
                                          FontAwesomeIcons.google,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 20.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    'Don\'t have an account? ',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 14,
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.pushNamed(
                                        context,'/register'
                                      );
                                    },
                                    child: const Text(
                                      "Register here",
                                      style: TextStyle(
                                        color: Color(0xff436331),
                                        fontSize: 14,
                                        fontFamily: 'Poppins',
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (_message.isNotEmpty)
                              Text(_message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.redAccent)),
                          ],
                        ),
                      ),
                    ),
                  ]
                ),
            ), 
            ]
          ),
        ),
    );
  }

  Future<void> _login() async {
    setState(() { _isLoading = true; _message = ''; });
    try {
      await _authService.signInWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
    } catch (e) {
      setState(() => _message = 'Error: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  
  Future<void> _googleSignIn() async {
    setState(() { _isLoading = true; _message = ''; });
    try {
      // Pass the context for navigation after successful sign-in
      await _authService.signInWithGoogle(context);
    } catch (e) {
      setState(() => _message = 'Error: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
