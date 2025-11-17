import 'package:cashit/backend/firebase_auth_service.dart';
import 'package:cashit/classes/RegistrationData.dart';
import 'package:cashit/classes/colors.dart';
import 'package:cashit/widget/form_container_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';

class Accountcreation extends StatefulWidget{
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

  Future<void> _register(RegistrationData data) async{
    if(!(_formKey.currentState?.validate() ?? false)){
      return;
    }

    if(_passwordController.text != _confirmPasswordController.text){
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password and Confirm Password do not match'))
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    final user = await _authService.signUpWithEmailAndPassword(
      data.email,
      _passwordController.text.trim(), 
      _usernameController.text.trim(),
      _fullnameController.text.trim(),
      data.idNum,
      data.birthLoc,
      data.birthDate,
      data.address,
      data.reason,
    );

    if (mounted) {
      setState(() { isLoading = false; });
    }

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
        if(didPop)return;
         Navigator.pop(context);
      },
      child: Center(
        child: Scaffold(
          body: Stack(
            children: [
              Container(
                color: Colors.white,
              ),
              SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Padding(
                        padding: EdgeInsetsGeometry.all(20),
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
                            )
                            ),
                          ),
                        )
                      ),
                      SizedBox(
                        child: Container(
                          width: 400,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                          ),
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
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                                child: FormContainerWidget(
                                  title: 'Username',
                                  iconPath: 'assets/IdentificationCard.svg',
                                  helperText: 'Enter your username',
                                  hintText: 'Enter your username',
                                  controller: _usernameController,
                                  inputType: TextInputType.text,
                                ),
                              ),
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
                                          child: InkWell(
                                            onTap: isLoading ? null:() => _register(registrationData), 
                                          child: Text(
                                            'Continue',
                                            textAlign: TextAlign.center,
                                            style: GoogleFonts.poppins(
                                              color: Colors.black,
                                              fontSize: 18,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          )
                                        ),
                                      )
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