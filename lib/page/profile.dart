import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cashit/page/userID.dart';
import 'package:cashit/widget/toast.dart';
import 'package:cashit/backend/firebase_auth_service.dart';
import 'package:cashit/widget/bottom_nav.dart';
import 'package:cashit/page/home.dart';
import 'package:cashit/page/transfers.dart';
import 'package:cashit/page/pin.dart';
import 'package:cashit/page/personalInformation.dart';
// import 'package:cashit/page/faceID.dart';
// import 'package:cashit/page/fingerprint.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseAuthService _authService = FirebaseAuthService();

  User? _user;
  bool _isSigningOut = false;
  bool _isUploadingPhoto = false;
  final ImagePicker _picker = ImagePicker();

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

  Future<void> _pickAndUploadPhoto() async {
    if (_isUploadingPhoto) return;
    try {
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        imageQuality: 80,
      );
      if (picked == null) return; // user cancelled

      setState(() => _isUploadingPhoto = true);

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        showToast(message: 'No user signed in');
        return;
      }

      final ref = FirebaseStorage.instance
          .ref()
          .child('profile_photos')
          .child('${user.uid}.jpg');

      // On web, the plugin returns no usable local File path. Use putData instead.
      TaskSnapshot snapshot;
      if (kIsWeb) {
        final bytes = await picked.readAsBytes();
        final uploadTask = ref.putData(
          bytes,
          SettableMetadata(contentType: 'image/jpeg'),
        );
        snapshot = await uploadTask;
      } else {
        final file = File(picked.path);
        final uploadTask = ref.putFile(
          file,
          SettableMetadata(contentType: 'image/jpeg'),
        );
        snapshot = await uploadTask;
      }

      final downloadUrl = await snapshot.ref.getDownloadURL();

      await user.updatePhotoURL(downloadUrl);
      await user.reload();
      _user = FirebaseAuth.instance.currentUser;
      showToast(message: 'Profile photo updated');
    } on FirebaseException catch (fe) {
      debugPrint(
        'FirebaseException during photo upload: ${fe.code} ${fe.message}',
      );
      showToast(message: 'Upload failed: ${fe.message ?? fe.code}');
    } catch (e, st) {
      debugPrint('Photo upload failed: $e');
      debugPrintStack(stackTrace: st);
      showToast(message: 'Failed to update profile photo: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  Future<void> _editDisplayName() async {
    final controller = TextEditingController(text: _user?.displayName ?? '');
    final result = await showDialog<String?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit display name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Full name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == null) return;
    if (result.isEmpty) {
      showToast(message: 'Name cannot be empty');
      return;
    }

    try {
      await _user?.updateDisplayName(result);
      await FirebaseAuth.instance.currentUser?.reload();
      _user = FirebaseAuth.instance.currentUser;
      showToast(message: 'Display name updated');
      setState(() {});
    } catch (e) {
      debugPrint('Failed to update displayName: $e');
      showToast(message: 'Failed to update name');
    }
  }

  Future<void> _handleLogout() async {
    if (_isSigningOut) return;
    setState(() => _isSigningOut = true);
    try {
      await _authService.signOut();
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      debugPrint('Logout failed: $e');
      showToast(message: 'Failed to log out');
    } finally {
      if (mounted) setState(() => _isSigningOut = false);
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 2,
        onTap: (idx) {
          if (idx == 2) return; // already on profile
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
                  child: const Align(
                    alignment: Alignment.topLeft,
                    child: SizedBox(width: 48),
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
                              onTap: _pickAndUploadPhoto,
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

                          if (_isUploadingPhoto)
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.35),
                                  borderRadius: BorderRadius.circular(44),
                                ),
                                child: const Center(
                                  child: SizedBox(
                                    width: 28,
                                    height: 28,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                    ),
                                  ),
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
                            onTap: _editDisplayName,
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
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PinPage()),
                    ),
                  ),
                  _buildTile(
                    icon: Icons.badge_outlined,
                    title: 'Personal Information',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PersonalInformationPage(),
                      ),
                    ),
                  ),
                  // _buildTile(
                  //   icon: Icons.face_rounded,
                  //   title: 'Face ID',
                  //   onTap: () => Navigator.push(
                  //     context,
                  //     MaterialPageRoute(builder: (_) => const FaceIDPage()),
                  //   ),
                  // ),
                  // _buildTile(
                  //   icon: Icons.fingerprint,
                  //   title: 'Fingerprint ID',
                  //   onTap: () => Navigator.push(
                  //     context,
                  //     MaterialPageRoute(
                  //       builder: (_) => const FingerprintPage(),
                  //     ),
                  //   ),
                  // ),

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
                          trailing: _isSigningOut
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : null,
                          onTap: _isSigningOut ? null : _handleLogout,
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
