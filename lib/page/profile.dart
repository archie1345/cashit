import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cashit/page/userID.dart';
import 'package:cashit/widget/toast.dart';
import 'package:cashit/backend/firebase_auth_service.dart';
import 'package:cashit/widget/bottom_nav.dart';
import 'package:cashit/page/home.dart';
import 'package:cashit/page/transfers.dart';
import 'package:cashit/page/notifications.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseAuthService _authService = FirebaseAuthService();

  User? _user;

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;
  }

  String _displayName() {
    final name = _user?.displayName;
    if (name == null || name.trim().isEmpty) {
      final email = _user?.email ?? '';
      return email.split('@').first;
    }
    return name;
  }

  String _usernameHandle() {
    final display = _displayName();
    return '@' + display.replaceAll(' ', '').toLowerCase();
  }

  Widget _buildTile({
    required IconData icon,
    required String title,
    VoidCallback? onTap,
    bool highlighted = false,
  }) {
    final tile = ListTile(
      leading: Icon(icon, color: Colors.black87),
      title: Text(title, style: const TextStyle(fontSize: 16.0)),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24.0),
    );

    if (highlighted) {
      return Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.blue.shade400, width: 2),
          borderRadius: BorderRadius.circular(6),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: tile,
      );
    }

    return Column(children: [tile, const Divider(height: 1)]);
  }

  Future<void> _handleLogout() async {
    try {
      await _authService.signOut();
      showToast(message: 'Signed out');
      // Optionally navigate to login screen if your app has one:
      // Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      debugPrint('Logout failed: $e');
      showToast(message: 'Failed to sign out');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 3,
        onTap: (idx) {
          if (idx == 3) return; // already on profile
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
          if (idx == 2)
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const NotificationsPage()),
            );
        },
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFDFF6DF), Color(0xFFE8D9FF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(0),
                      bottomRight: Radius.circular(0),
                    ),
                  ),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.maybePop(context),
                    ),
                  ),
                ),

                // Avatar and name
                Positioned(
                  top: 40,
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 44,
                            backgroundColor: Colors.grey.shade200,
                            backgroundImage: _user?.photoURL != null
                                ? NetworkImage(_user!.photoURL!)
                                      as ImageProvider
                                : null,
                            child: _user?.photoURL == null
                                ? Text(
                                    _displayName().isNotEmpty
                                        ? _displayName()[0].toUpperCase()
                                        : '',
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : null,
                          ),
                          Positioned(
                            right: -4,
                            bottom: -4,
                            child: GestureDetector(
                              onTap: () => showToast(
                                message:
                                    'Change profile photo (not implemented)',
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.all(6),
                                child: const Icon(Icons.camera_alt, size: 18),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _displayName(),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => showToast(
                              message: 'Edit profile (not implemented)',
                            ),
                            child: const Icon(Icons.edit, size: 18),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _usernameHandle(),
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(top: 72.0),
                children: [
                  const SizedBox(height: 8),
                  _buildTile(
                    icon: Icons.perm_identity_outlined,
                    title: 'User ID',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const UserIDPage()),
                    ),
                  ),
                  _buildTile(
                    icon: Icons.lock_outline,
                    title: 'PIN',
                    onTap: () => showToast(message: 'Open PIN settings'),
                  ),
                  _buildTile(
                    icon: Icons.badge_outlined,
                    title: 'Personal Information',
                    onTap: () =>
                        showToast(message: 'Open personal information'),
                  ),
                  _buildTile(
                    icon: Icons.face_rounded,
                    title: 'Face ID',
                    highlighted: true,
                    onTap: () => showToast(message: 'Configure Face ID'),
                  ),
                  _buildTile(
                    icon: Icons.fingerprint,
                    title: 'Fingerprint ID',
                    onTap: () => showToast(message: 'Configure fingerprint ID'),
                  ),

                  const SizedBox(height: 24),

                  // Logout
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.logout_outlined),
                          title: const Text(
                            'Log Out',
                            style: TextStyle(fontSize: 16.0),
                          ),
                          onTap: _handleLogout,
                        ),
                        const Divider(height: 1),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
