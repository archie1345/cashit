import 'package:cashit/classes/colors.dart';
import 'package:cashit/widget/form_container_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';


class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  static const pastelGreen = ColorPalletes.pastelGreen;
  static const pastelpurple = ColorPalletes.pastelpurple;
  static const pastelPink = ColorPalletes.pastelPink;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _onContinue(){
    if(_formKey.currentState?.validate() ?? false){
      Navigator.pushNamed(context, '/registerform',
      arguments: _emailController.text.trim(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
                      Padding(padding: const EdgeInsets.all(20.0),
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
                      ),
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
                                padding: const EdgeInsets.all(30.0),
                                child: Center(
                                  child: Image.asset('assets/image.png')),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: FormContainerWidget(
                                  title: 'Email',
                                  iconPath: 'assets/mail.svg',
                                  helperText: 'Enter your email',
                                  hintText: 'Enter your email',
                                  controller: _emailController,
                                  inputType: TextInputType.emailAddress,
                                  validator: (val) {
                                    if (val == null || val.isEmpty) {
                                      return 'Please enter an email';
                                    }
                                    if (!val.contains('@') || !val.contains('.')) {
                                      return 'Please enter a valid email';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(20.0),
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
                                          child: GestureDetector(
                                            onTap: _onContinue,
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