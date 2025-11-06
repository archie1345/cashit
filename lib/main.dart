import 'dart:io';
import 'package:cashit/page/login.dart';
import 'package:cashit/page/register.dart';
import 'package:cashit/page/registerForm.dart';
import 'package:cashit/page/splashScreen.dart';
import 'package:cashit/testing/auth_wrapper.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterError.onError = (FlutterErrorDetails details) {
    debugPrint('FlutterError caught: ${details.exceptionAsString()}');
    if (details.stack != null) {
      debugPrintStack(stackTrace: details.stack);
    }
  };

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  bool isStripeSupported = false;
  if (kIsWeb) {
    isStripeSupported = true;
  } else {
    try{
      if(Platform.isAndroid || Platform.isIOS){
        isStripeSupported = true;
      }
    }catch(e){
      isStripeSupported = false;
    }
  }

  if(isStripeSupported){
    Stripe.publishableKey = "pk_test_51SIQfcKB84pAaJ2EDDbGR9JLqbOPLi9dNP1SLiHn1PpjW1ZsZMfc4M9FYegYalQr0jRF5REYUiUDvdphCXADvrwT00cpg44yLb";
    if (!kIsWeb) {
      await Stripe.instance.applySettings();
    }
  }


  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CashIt',
      // home: const AuthWrapper(),
      routes: {
        '/': (context) => const Splashscreen(),
        '/login': (context) => const LoginPage(),
        '/home': (context) => const AuthWrapper(),
        '/register': (context) => const RegisterPage(),
        '/registerform': (context) => Registerform(),
        
      }
    );
  }
}

