import 'package:cashit/classes/RegistrationData.dart';
import 'package:cashit/classes/colors.dart';
import 'package:cashit/widget/form_container_widget.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Registerform extends StatefulWidget{
  const Registerform({super.key});

  @override
  State<Registerform> createState() => _RegisterformState();
}

class _RegisterformState extends State<Registerform> {

  final _idNumController = TextEditingController();
  final _birthLocController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _addressController = TextEditingController();
  final _reasonController = TextEditingController();
  static const pastelGreen = ColorPalletes.pastelGreen;
  static const pastelpurple = ColorPalletes.pastelpurple;
  static const pastelPink = ColorPalletes.pastelPink;
  final _formKey = GlobalKey<FormState>();
  bool isLoading = false;

  Future<void> _onContinue(String email) async{
    if(!(_formKey.currentState?.validate() ?? false)){
      return;
    }

    setState(() {
      isLoading = true;
    });
    
    final registrationData = RegistrationData(
      email: email,
      idNum: _idNumController.text.trim(),
      birthLoc: _birthLocController.text.trim(),
      birthDate: _birthDateController.text.trim(),
      address: _addressController.text.trim(),
      reason: _reasonController.text.trim(),
    );

    if (mounted) {
      setState(() { isLoading = false; });
    }
    Navigator.pushNamed(context, '/accountcreation',
      arguments: registrationData,
    );
  }

  @override
  Widget build(BuildContext context) {
    final String email = ModalRoute.of(context)!.settings.arguments as String;

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
                            'Registration Form',
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
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: 400,
                        ),
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20.0),
                              child: FormContainerWidget(
                                title: 'Identification Number (NIK)',
                                helperText: 'Enter Identificaion Number',
                                hintText: 'Enter Identificaion Number',
                                controller: _idNumController,
                                inputType: TextInputType.text,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20.0),
                              child: FormContainerWidget(
                                title: 'Birth Location',
                                helperText: 'Enter Birth Location',
                                hintText: 'Enter Birth Location',
                                controller: _birthLocController,
                                inputType: TextInputType.text,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20.0),
                              child: FormContainerWidget(
                                title: 'Birth Date',
                                helperText: 'Enter Birth Date',
                                hintText: 'Enter Birth Date',
                                isDatePicker: true,
                                controller: _birthDateController,
                                validator: (val) {
                                  if (val == null || val.isEmpty) {
                                    return 'Please select a date';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20.0),
                              child: FormContainerWidget(
                                title: 'Address',
                                helperText: 'Enter Address',
                                hintText: 'Enter Address',
                                controller: _addressController,
                                inputType: TextInputType.text,
                                ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20.0),
                              child: FormContainerWidget(
                                title: 'Reason for Opening Account',
                                helperText: 'Enter Reason for Opening Account',
                                hintText: 'Enter Reason for Opening Account',
                                controller: _reasonController,
                                inputType: TextInputType.text,
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
                                          onTap: isLoading ? null:() => _onContinue(email), 
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