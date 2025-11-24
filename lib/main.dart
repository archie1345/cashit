import 'dart:io';
import 'package:cashit/page/addBalancePage.dart';
import 'package:cashit/page/createPin.dart';
import 'package:cashit/page/historyPage.dart';
import 'package:cashit/page/login.dart';
import 'package:cashit/page/profile.dart';
import 'package:cashit/page/register.dart';
import 'package:cashit/page/accountCreation.dart';
import 'package:cashit/page/registrationForm.dart';
import 'package:cashit/page/splashScreen.dart';
import 'package:cashit/page/home.dart';
import 'package:cashit/page/topUpMenu.dart';
import 'package:cashit/page/transactionStatus.dart';
import 'package:cashit/page/transfers.dart';
import 'package:cashit/page/forgot_password.dart';
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

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  bool isStripeSupported = false;
  if (kIsWeb) {
    isStripeSupported = true;
  } else {
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        isStripeSupported = true;
      }
    } catch (e) {
      isStripeSupported = false;
    }
  }

  if (isStripeSupported) {
    Stripe.publishableKey =
        "pk_test_51SIQfcKB84pAaJ2EDDbGR9JLqbOPLi9dNP1SLiHn1PpjW1ZsZMfc4M9FYegYalQr0jRF5REYUiUDvdphCXADvrwT00cpg44yLb";
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
      routes: {
        '/': (context) => const Splashscreen(),
        '/login': (context) => const LoginPage(),
        '/home': (context) => const Homepage(),
        '/register': (context) => const RegisterPage(),
        '/forgotpassword': (context) => const ForgotPasswordPage(),
        '/registerform': (context) => Registerform(),
        '/accountcreation': (context) => Accountcreation(),
        '/create_pin': (context) => CreatePinPage(),
        '/history': (context) => HistoryPage(),
        '/add_balance': (context) => Addbalancepage(),
        '/transfer': (context) => const TransfersPage(),
        '/profile': (context) => const ProfilePage(),
        '/topUpMenu': (context) => const TopUpMenuPage(),
        '/transactionStatus': (context) {
          final args =
              ModalRoute.of(context)?.settings.arguments
                  as Map<String, dynamic>?;
          return TransactionstatusPage(
            amount: args?['amount'],
            type: args?['type'],
            isSuccess: args?['isSuccess'],
            transactionDate: args?['transactionDate'],
            serviceName: args?['serviceName'],
          );
        },

        // '/add_balance_success':(context) =>
      },
    );
  }
}
