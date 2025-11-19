import 'package:cashit/widget/bottom_nav.dart';
import 'package:flutter/material.dart';
import 'package:cashit/page/home.dart';
import 'package:cashit/page/transfers.dart';
import 'package:cashit/page/profile.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    void _onTap(int idx) {
      if (idx == 0)
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const Homepage()),
        );
      if (idx == 1)
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const TransfersPage()),
        );
      if (idx == 2) return; // already on Notifications
      if (idx == 3)
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ProfilePage()),
        );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: const Center(child: Text('Notifications - placeholder')),
      bottomNavigationBar: BottomNavBar(currentIndex: 2, onTap: _onTap),
    );
  }
}
