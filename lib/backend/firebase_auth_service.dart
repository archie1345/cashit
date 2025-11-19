import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cashit/widget/toast.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
const String baseUrl = "https://api-cksvvgpqtq-uc.a.run.app";


class FirebaseAuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Sign up a new user
  Future<User?> signUpWithEmailAndPassword(
    String email,
    String password,
    String username,
    String fullname,
    String idNum,
    String birthLoc,
    String birthDate,
    String address,
    String reason,
    ) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        throw FirebaseAuthException(
          code: 'user-creation-failed',
          message: 'User creation failed.',
        );
      }
      await user.updateDisplayName(username);
      await user.reload();
      final refreshedUser = _firebaseAuth.currentUser!;
      final uid = refreshedUser.uid;

      // Save user to Firestore
      await _firestore.collection('users').doc(uid).set({
        'uid': uid,
        'email': email,
        'username': username,
        'fullname': fullname,
        'createdAt': Timestamp.now(),
        'balance': 0,
        'nik': idNum,
        'birthLocation': birthLoc,
        'birthDate': birthDate,
        'address': address,
        'accountReason': reason,
        'stripeAccountId': null,
        'pinHash': null,
      });

      await _onboardUserToStripe(refreshedUser, username);

      return refreshedUser;
    } catch (e) {
      debugPrint('Error during signup: $e');
      if (e is FirebaseAuthException) {
        handleAuthException(e);
      }
      return null;
    }
  }

   // Create a new Stripe customer and save the ID to Firestore
  Future<void> createStripeCustomer(String userId) async {
    try {
      final currentUser = _firebaseAuth.currentUser;
      if (currentUser == null) {
        debugPrint("Error: User is not signed in.");
        throw Exception("User is not signed in.");
      }

      // Force refresh the token to ensure it's not stale
      final idToken = await currentUser.getIdToken(true);
      
      final email = currentUser.email;
      final username = currentUser.displayName ?? currentUser.email;

      final response = await http.post(
        Uri.parse("https://api-cksvvgpqtq-uc.a.run.app/"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $idToken",
        },
        body: jsonEncode({
          "email": email,
          "username": username,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint("Stripe customer created: $data");

        await FirebaseFirestore.instance.collection('nasabah').doc(userId).set({
          'stripeCustomerId': data['customerId'],
          'email': email,
          'username': username,
        });
      } else {
        debugPrint('Failed to create Stripe customer: ${response.body}');
        throw Exception('Failed to create Stripe customer');
      }
    } catch (e) {
      debugPrint('Error creating Stripe customer: $e');
      throw Exception('Failed to create Stripe customer');
    }
  }

  // Sign in an existing user with email and password.
  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
        case 'wrong-password':
          _showPlatformToast(message: 'Invalid email or password.');
          break;
        default:
          _showPlatformToast(message: 'An error occurred: ${e.message}');
      }
      debugPrint('FirebaseAuthException: ${e.code}, ${e.message}');
    } catch (e) {
      debugPrint('Unexpected error: $e');
      _showPlatformToast(message: 'An unexpected error occurred.');
    }
    return null;
  }

Future<bool> createPin(String pin) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw Exception('User is not logged in.');
      }

      final idToken = await user.getIdToken(true);
      final response = await http.post(
        Uri.parse("$baseUrl/api/create-pin"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $idToken",
        },
        body: jsonEncode({"pin": pin}),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        debugPrint('Failed to save PIN: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Error in createPin: $e');
      return false;
    }
  }

void onUserLogin() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    await createStripeCustomer(user.uid);
  }
}

  Future<void> signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      // await GoogleSignIn.instance.disconnect();
      _showPlatformToast(message: "Successfully signed out.");
    } catch (e) {
      debugPrint('Sign-Out Error: $e');
      _showPlatformToast(message: "Error signing out: $e");
    }
  }

  // Handle FirebaseAuth exceptions
  void handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        _showPlatformToast(message: 'The email address is already in use.');
        break;
      case 'weak-password':
        _showPlatformToast(message: 'The password is too weak.');
        break;
      case 'invalid-email':
        _showPlatformToast(message: 'Invalid email address.');
        break;
      default:
        _showPlatformToast(message: 'FirebaseAuth error: ${e.message}');
    }
    debugPrint('FirebaseAuthException: ${e.code}, ${e.message}');
  }

  Future<void> _onboardUserToStripe(User user, String username) async {
    try {
      final idToken = await user.getIdToken(true);
      
      final response = await http.post(
        Uri.parse("$baseUrl/api/onboard-user-account"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $idToken",
        },
        body: jsonEncode({"username": username}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final onboardingUrl = data['onboardingUrl'];
        if (onboardingUrl != null) {
          final uri = Uri.parse(onboardingUrl);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, webOnlyWindowName: '_blank');
          }
        }
      } else {
        print('Failed to onboard Stripe account: ${response.body}');
        throw Exception('Failed to onboard Stripe account.');
      }
    } catch (e) {
      print('Error during Stripe onboarding call: $e');
    }
  }
}

void _showPlatformToast({required String message}) {
  bool isDesktop = false;
  try {
    isDesktop = Platform.isWindows || Platform.isLinux || Platform.isMacOS;
  } catch (e) {
    isDesktop = false;
  }

  if (!kIsWeb && isDesktop) {
    debugPrint("Toast message: $message");
  } else {
    showToast(message: message);
  }
}

// Future<void> signInWithGoogle(BuildContext context) async {
  
//   try{
//     if (Platform.isWindows) {
//         throw UnimplementedError("Google Sign-In is not supported on Windows.");
//      }
//   } catch(e){
//     _showPlatformToast(message: "Google Sign-In is not supported on this platform.");
//     debugPrint('Google Sign-In Error: Unimplemented on this platform.');
//     return;
//   }

//   try{
//     final configUrl = Uri.parse('$baseUrl/api/config');
//     final response = await http.get(configUrl);

//     if (response.statusCode != 200) {
//       _showPlatformToast(message: "Error connecting to server.");
//       return;
//     }
//     final config = json.decode(response.body);
//     final clientId = config['googleClientId'];

//     if (clientId == null || clientId.isEmpty) {
//       _showPlatformToast(message: "Server configuration error.");
//       return;
//     }
//     await _googleSignIn.initialize(serverClientId: clientId);

//     final GoogleSignInAccount user = await _googleSignIn.authenticate();

//     final GoogleSignInClientAuthorization? authorization = await user.authorizationClient.authorizationForScopes(['email','profile']);

//     final GoogleSignInAuthentication authentication = user.authentication;

//     if (authorization == null) {
//         _showPlatformToast(message: "failed to retrieve authorization tokens.");
//         return;
//       }

//     final OAuthCredential credential = GoogleAuthProvider.credential(
//       accessToken: authorization.accessToken,
//       idToken: authentication.idToken,
//     );
//     final UserCredential userCredential = await _firebaseAuth.signInWithCredential(credential);

//     final userData = userCredential.user;

//     if (userData != null) {
//       final userDoc = await _firestore.collection('users').doc(userData.uid).get();
//       if (!userDoc.exists) {
//           // This is a new user, so we save them to Firestore and onboard them
//           print('New Google user detected. Onboarding to Stripe...');
//           await _firestore.collection('users').doc(userData.uid).set({
//             'username': userData.displayName ?? '',
//             'email': userData.email ?? '',
//             'uid': userData.uid,
//             'createdAt': FieldValue.serverTimestamp(),
//           });
//           // Call the same onboarding function as the email signup.
//           await _onboardUserToStripe(userData, userData.displayName ?? 'New User');
//         }
//       await createStripeCustomer(userData.uid);

//       await _firestore.collection('users').doc(userData.uid).set({
//         'username': userData.displayName ?? '',
//         'email': userData.email ?? 'N/A',
//         'uid': userData.uid,
//         'createdAt': FieldValue.serverTimestamp(),
//       }, SetOptions(merge: true));
//     }

//     _showPlatformToast(message: "Signed in succesfully");
//     Navigator.pushReplacementNamed(context, "/home");
//   } on FirebaseAuthException catch (e) {
//       _showPlatformToast(message: "Firebase Auth Error: ${e.message}");
//       debugPrint('Firebase Auth Error: $e');
//     } catch (e) {
//       debugPrint('Google Sign-In Error: $e');
//       _showPlatformToast(message: "An unexpected error occurred during Google Sign-In.");
//   }
// }
