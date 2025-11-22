import 'dart:async';
import 'package:cashit/classes/colors.dart';
import 'package:cashit/page/transactionStatus.dart';
import 'package:cashit/widget/recentTransaction.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cashit/widget/bottom_nav.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:app_links/app_links.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> with WidgetsBindingObserver {
  Timer? _inactivityTimer;
  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;
  final _timeoutDuration = const Duration(minutes: 5);
  String? _userId;
  bool _isBalanceVisible = true;
  Stream<DocumentSnapshot>? _balanceStream;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _userId = FirebaseAuth.instance.currentUser?.uid;
    if (_userId != null) {
      _balanceStream = FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .snapshots();
    }
    _appLinks = AppLinks();
    _handleIncomingLinks();
    _checkInitialLink();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _inactivityTimer?.cancel();
    _linkSubscription?.cancel();
    super.dispose();
  }

  Future<void> _checkInitialLink() async {
    try {
      final uri = await _appLinks.getInitialLink();
      if (uri != null) {
        _handleDeepLink(uri);
      }
    } catch (e) {
      debugPrint('Error checking initial link: $e');
    }
  }

  void _handleIncomingLinks() {
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (Uri uri) {
        if (!mounted) return;
        _handleDeepLink(uri);
      },
      onError: (err) {
        debugPrint('Got error listening to incoming links: $err');
      },
    );
  }

  void _handleDeepLink(Uri uri) async {
    debugPrint("Received deep link: $uri");
    final prefs = await SharedPreferences.getInstance();

    if (uri.toString().contains('checkout/success')) {
      final amount = prefs.getInt('pending_topup_amount');

      if (amount != null) {
        await prefs.remove('pending_topup_amount');

        if (!mounted) return;
        Navigator.pushNamed(
          context,
          '/transactionStatus',
          arguments: (
            type: TransactionType.transfer,
            isSuccess: true,
            amount: amount,
            transactionDate: DateTime.now(),
          ),
        );
      }
    } else if (uri.toString().contains('checkout/cancel')) {
      final amount = prefs.getInt('pending_topup_amount') ?? 0;
      await prefs.remove('pending_topup_amount');

      if (!mounted) return;

      Navigator.of(
        context,
      ).popUntil((route) => route.isFirst || route.settings.name == '/home');
      Navigator.pushNamed(
        context,
        '/transactionStatus',
        arguments: (
          type: TransactionType.transfer,
          isSuccess: false,
          amount: amount,
          transactionDate: DateTime.now(),
        ),
      );
    }
  }

  Future<void> _signOutAndNavigate() async {
    _inactivityTimer?.cancel();

    if (FirebaseAuth.instance.currentUser != null) {
      await FirebaseAuth.instance.signOut();
      print("User signed out.");

      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
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
        _inactivityTimer?.cancel();
        _inactivityTimer = Timer(_timeoutDuration, _onInactivitySignOut);
        print("Timer Started: App Paused");
        break;
      case AppLifecycleState.detached:
        print("App Detached");
        _signOutAndNavigate();
        break;
      case AppLifecycleState.hidden:
        _inactivityTimer?.cancel();
        _inactivityTimer = Timer(_timeoutDuration, _onInactivitySignOut);
        print("Timer Started: App is in background ($state)");
        break;
      case AppLifecycleState.inactive:
        _inactivityTimer?.cancel();
        _inactivityTimer = Timer(_timeoutDuration, _onInactivitySignOut);
        print("Timer Started: App Inactive");
        break;
    }
  }

  Widget _buildMenuButton({
    required String label,
    required String svgPath,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: SvgPicture.asset(svgPath, height: 24, width: 24),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 12),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      ColorPalletes.pastelGreen,
                      ColorPalletes.pastelpurple,
                      ColorPalletes.pastelPink,
                    ],
                    stops: [0.3, 0.75, 1.0],
                  ),
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: 400),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SvgPicture.asset(
                                      'assets/logo_text.svg',
                                      width: 150,
                                    ),
                                    Row(
                                      children: [
                                        Text(
                                          'Hello, ',
                                          textAlign: TextAlign.left,
                                          style: GoogleFonts.inter(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        Text(
                                          '${FirebaseAuth.instance.currentUser?.displayName ?? 'User'}!',
                                          textAlign: TextAlign.left,
                                          style: GoogleFonts.inter(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 10.0,
                                      ),
                                      child: Text(
                                        'Total Balance',
                                        style: GoogleFonts.inter(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                                    StreamBuilder<DocumentSnapshot>(
                                      stream: _balanceStream,
                                      builder: (context, snapshot) {
                                        if (snapshot.connectionState ==
                                            ConnectionState.waiting) {
                                          return const CircularProgressIndicator();
                                        }
                                        if (snapshot.hasError) {
                                          return const Text(
                                            "Error loading balance",
                                            style: TextStyle(color: Colors.red),
                                          );
                                        }
                                        if (!snapshot.hasData ||
                                            !snapshot.data!.exists) {
                                          return const Text(
                                            "Balance: N/A",
                                            style: TextStyle(
                                              color: Colors.grey,
                                            ),
                                          );
                                        }

                                        final data =
                                            snapshot.data!.data()
                                                as Map<String, dynamic>;
                                        final balance = data['balance'] ?? 0;

                                        final formattedBalance =
                                            NumberFormat.currency(
                                              locale: 'en_US',
                                              symbol: '\$',
                                              decimalDigits: 2,
                                            ).format(balance/100);

                                        final hiddenBalance = '\$ ••••••••';

                                        return Row(
                                          children: [
                                            Text(
                                              _isBalanceVisible
                                                  ? formattedBalance
                                                  : hiddenBalance,
                                              style: GoogleFonts.inter(
                                                fontSize: 28,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.black,
                                              ),
                                            ),
                                            IconButton(
                                              icon: Icon(
                                                _isBalanceVisible
                                                    ? Icons.visibility_off
                                                    : Icons.visibility,
                                                color: Colors.grey[700],
                                              ),
                                              onPressed: () {
                                                setState(() {
                                                  _isBalanceVisible =
                                                      !_isBalanceVisible;
                                                });
                                              },
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10.0,
                            ),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 400),
                              child: Container(
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(20),
                                  ),
                                  color: Colors.white,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(10.0),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      _buildMenuButton(
                                        label: 'Add \nbalance',
                                        svgPath: 'assets/add_Balance.svg',
                                        onTap: () {
                                          Navigator.pushNamed(
                                            context,
                                            '/add_balance',
                                          );
                                        },
                                      ),
                                      _buildMenuButton(
                                        label: 'Top Up',
                                        svgPath: 'assets/top-up.svg',
                                        onTap: () {
                                          Navigator.pushNamed(context, '/topUpMenu');
                                        },
                                      ),
                                      _buildMenuButton(
                                        label: 'Transfer',
                                        svgPath: 'assets/transfer.svg',
                                        onTap: () {
                                          Navigator.pushNamed(context, '/transfer');
                                        },
                                      ),
                                      _buildMenuButton(
                                        label: 'History',
                                        svgPath: 'assets/history.svg',
                                        onTap: () {
                                          Navigator.pushNamed(context, '/history',);
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Padding(
                          //   padding: const EdgeInsets.all(8.0),
                          //   child: ElevatedButton.icon(
                          //     onPressed: () {
                          //       Navigator.pushNamed(context, '/testing');
                          //     },
                          //     icon: const Icon(Icons.bug_report, size: 16),
                          //     label: const Text("Go to Testing Page"),
                          //     style: ElevatedButton.styleFrom(
                          //       backgroundColor: Colors.orange,
                          //       foregroundColor: Colors.white,
                          //       shape: RoundedRectangleBorder(
                          //         borderRadius: BorderRadius.circular(20)
                          //       )
                          //     ),
                          //   ),
                          // ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 20,
                            ),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: 400,
                                maxHeight: 420,
                              ),
                              child: RecentTransactions(
                                limit: 4,
                              ),
                            ),
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
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 0,
        onTap: (idx) {
          if (idx == 0) return; // already on home
          if (idx == 1) {
            Navigator.pushReplacementNamed(context, '/transfer');
          }
          if (idx == 2) {
            Navigator.pushReplacementNamed(context, '/profile');
          }
        },
      ),
    );
  }
}
