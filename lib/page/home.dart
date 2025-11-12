import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class Homepage extends StatefulWidget{
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> with WidgetsBindingObserver{
  Timer? _inactivityTimer;
  final _timeoutDuration = const Duration(minutes: 5);
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _signOut() {
    // You might want to check if the user is still mounted or logged in
    if (FirebaseAuth.instance.currentUser != null) {
      FirebaseAuth.instance.signOut();
      print("User signed out due to inactivity.");
    }
  }

   Future<void> _signOutAndNavigate() async {
    // Check if a user is currently signed in
    if (FirebaseAuth.instance.currentUser != null) {
      await FirebaseAuth.instance.signOut();
      print("User signed out.");

      // After sign out, navigate back to login and remove all previous routes
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/login',
          (route) => false, // This predicate removes all routes
        );
      }
    }
  }

  void _onInactivitySignOut() {
    print("User signed out due to inactivity.");
    _signOutAndNavigate();
  }

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        _inactivityTimer?.cancel();
        print("Timer Canceled: App Resumed");
        break;
      case AppLifecycleState.paused:
        _inactivityTimer?.cancel(); // Cancel any existing timer
        _inactivityTimer = Timer(_timeoutDuration, _signOut);
        print("Timer Started: App Paused");
        break;
      case AppLifecycleState.detached:
        print("App Detached");
        break;
      case AppLifecycleState.hidden:
        break;
      case AppLifecycleState.inactive:
        _inactivityTimer?.cancel();
        _inactivityTimer = Timer(_timeoutDuration, _onInactivitySignOut);
        print("Timer Started: App Inactive");
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Page'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: _signOutAndNavigate,
          ),
        ],
      ),
      body: Center(
        child: Text('Home Page'),
      ),
    );
  }
}