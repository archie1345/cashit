import 'package:cashit/classes/colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class Splashscreen extends StatefulWidget {
  const Splashscreen({super.key});
  static const pastelGreen = ColorPalletes.pastelGreen;
  static const pastelpurple = ColorPalletes.pastelpurple;
  static const pastelPink = ColorPalletes.pastelPink;

  @override
  State<Splashscreen> createState() => _SplashscreenState();
}

class _SplashscreenState extends State<Splashscreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNextScreen();
  }

  Future<void> _navigateToNextScreen() async {
    await Future.delayed(const Duration(seconds: 3));

    // Check if a user is logged in
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      // Navigate to the HomePage
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      // Navigate to the LoginPage
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Scaffold(
        body: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Splashscreen.pastelGreen, Splashscreen.pastelpurple, Splashscreen.pastelPink],
                  stops: [0.3, 0.75, 1.0],
                ),
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                  Padding(
                    padding: const EdgeInsets.only(top:150,bottom: 180),
                    child: SizedBox(
                      height: 200,
                      width: 200,
                      child: Container(
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          color: Colors.black,
                        ),
                        child: SvgPicture.asset('assets/logo.svg'),
                      ),
                    ),
                  ),
                  Divider(
                    color: Colors.black, // Color of the line
                    height: 10, // Height of the divider (includes padding)
                    thickness: 2, // Thickness of the actual line
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 10,bottom:5, left: 30, right: 30),
                    child: Text(
                      'Secure Your Financial Future With Us.',
                      textAlign: TextAlign.left,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                      )
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: Text(
                      'Your Finanial Future, our priority. Sucure your finances with Cashit\'s trusted banking services.'
                    ),
                  ),
                  // Padding(
                  //   padding: const EdgeInsets.only(top: 80),
                  //   child: Row(
                  //     mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  //     children: [
                  //       ElevatedButton(
                  //         onPressed: () {
                  //         },
                  //         style: ElevatedButton.styleFrom(
                  //           backgroundColor: Colors.black,
                  //           padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  //           shape: RoundedRectangleBorder(
                  //             borderRadius: BorderRadius.circular(50),
                  //           ),
                  //         ),
                  //         child: Text(
                  //           'Login',
                  //           style: TextStyle(
                  //             fontSize: 18,
                  //             fontWeight: FontWeight.bold,
                  //             color: Colors.white,
                  //           ),
                  //         ),
                  //       ),
                  //       ElevatedButton(
                  //         onPressed: () {
                  //         },
                  //         style: ElevatedButton.styleFrom(
                  //           backgroundColor: Colors.white,
                  //           padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  //           shape: RoundedRectangleBorder(
                  //             borderRadius: BorderRadius.circular(50),
                  //           ),
                  //         ),
                  //         child: Text(
                  //           'Sign Up',
                  //           style: TextStyle(
                  //             fontSize: 18,
                  //             fontWeight: FontWeight.bold,
                  //             color: Colors.black,
                  //           ),
                  //         ),
                  //       ),
                  //     ]
                  //   ),
                  // ),  
                ]
              ), 
            ]
          ),
        ),
    );
  }
}
