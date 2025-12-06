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
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseAuthService _authService = FirebaseAuthService();

  User? _user;
  bool _isSigningOut = false;
  bool _isUploadingPhoto = false;
  int _lastUploadTimestamp = DateTime.now().millisecondsSinceEpoch;
  
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
    return '@${display.replaceAll(' ', '').toLowerCase()}';
  }

  Future<void> _pickAndUploadPhoto() async {
    if (_isUploadingPhoto) return;
    try {
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        imageQuality: 90,
      );
      
      if (picked == null) return;

      setState(() => _isUploadingPhoto = true);

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        showToast(message: 'No user signed in');
        return;
      }

      final Uint8List originalBytes = await picked.readAsBytes();
      if (originalBytes.isEmpty) {
        showToast(message: 'Error: Image is empty');
        return;
      }
      
      Uint8List uploadData = originalBytes;
      String contentType = 'image/jpeg'; 
      bool compressionSuccess = false;

      final bool isSupportedPlatform = kIsWeb || 
                                       defaultTargetPlatform == TargetPlatform.android || 
                                       defaultTargetPlatform == TargetPlatform.iOS || 
                                       defaultTargetPlatform == TargetPlatform.macOS;

      if (isSupportedPlatform) {
        try {
          final compressedBytes = await FlutterImageCompress.compressWithList(
            originalBytes,
            minHeight: 512,
            minWidth: 512,
            quality: 70,
          );
          if (compressedBytes.isNotEmpty) {
            uploadData = compressedBytes;
            compressionSuccess = true; 
          }
        } catch (e) {
          debugPrint("Compression skipped/failed: $e");
        }
      }
      
      if (!compressionSuccess) {
        final String extension = picked.name.split('.').last.toLowerCase();
        if (extension == 'png') contentType = 'image/png';
        if (extension == 'webp') contentType = 'image/webp';
      }

      final ref = FirebaseStorage.instance
          .ref()
          .child('profile_photos')
          .child('${user.uid}.jpg'); // Storing as .jpg is fine if metadata is correct

      final uploadTask = ref.putData(
        uploadData,
        SettableMetadata(contentType: contentType),
      );
      
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      await NetworkImage(downloadUrl).evict();
      PaintingBinding.instance.imageCache.clear();

      await user.updatePhotoURL(downloadUrl);
      await user.reload();
      
      setState(() {
        _user = FirebaseAuth.instance.currentUser;
        _lastUploadTimestamp = DateTime.now().millisecondsSinceEpoch;
      });
      
      showToast(message: 'Profile photo updated');
    } on FirebaseException catch (fe) {
      debugPrint('Storage Error: ${fe.code} ${fe.message}');
      showToast(message: 'Upload failed. Check permissions.');
    } catch (e) {
      debugPrint('General Error: $e');
      showToast(message: 'Failed to update photo');
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
      setState(() {
         _user = FirebaseAuth.instance.currentUser;
      });
      showToast(message: 'Display name updated');
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
    String? photoUrl = _user?.photoURL;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 2,
        onTap: (idx) {
          if (idx == 2) return; 
          if (idx == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const Homepage()),
            );
          }
          if (idx == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const TransfersPage()),
            );
          }
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
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFDFF6DF), Color(0xFFE8D9FF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
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
                          Container(
                            width: 88, 
                            height: 88,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.grey.shade200,
                              border: Border.all(color: Colors.white, width: 3),
                            ),
                            child: ClipOval(
                              child: photoUrl != null
                                  ? Image.network(
                                      photoUrl,
                                      key: ValueKey("$_lastUploadTimestamp"), 
                                      fit: BoxFit.cover,
                                      loadingBuilder: (context, child, loadingProgress) {
                                        if (loadingProgress == null) return child;
                                        return const Center(
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        );
                                      },
                                      errorBuilder: (context, error, stackTrace) {
                                        debugPrint("Image Display Error: $error");
                                        return const Icon(Icons.person, size: 40, color: Colors.grey);
                                      },
                                    )
                                  : Center(
                                      child: Text(
                                        _displayName().isNotEmpty
                                            ? _displayName()[0].toUpperCase()
                                            : '',
                                        style: const TextStyle(
                                          fontSize: 28,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                            ),
                          ),
                          
                          // Camera Icon
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: GestureDetector(
                              onTap: _pickAndUploadPhoto,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: const [
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
                                  shape: BoxShape.circle,
                                ),
                                child: const Center(
                                  child: SizedBox(
                                    width: 28,
                                    height: 28,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
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