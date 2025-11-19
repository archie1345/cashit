import 'package:cashit/widget/bottom_nav.dart';
import 'package:flutter/material.dart';
import 'package:cashit/page/home.dart';
import 'package:cashit/page/notifications.dart';
import 'package:cashit/page/profile.dart';

class TransfersPage extends StatelessWidget {
  const TransfersPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    void _onTap(int idx) {
      if (idx == 0)
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const Homepage()),
        );
      if (idx == 1) return; // already on Transfers
      if (idx == 2)
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const NotificationsPage()),
        );
      if (idx == 3)
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ProfilePage()),
        );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Transfers')),
      body: const Center(child: Text('Transfers - placeholder')),
      bottomNavigationBar: BottomNavBar(currentIndex: 1, onTap: _onTap),
    );
  }
}
