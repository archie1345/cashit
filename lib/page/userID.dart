import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cashit/widget/toast.dart';

class UserIDPage extends StatefulWidget {
  const UserIDPage({Key? key}) : super(key: key);

  @override
  State<UserIDPage> createState() => _UserIDPageState();
}

class _UserIDPageState extends State<UserIDPage> {
  final TextEditingController _currentController = TextEditingController();
  final TextEditingController _newController = TextEditingController();
  User? _user;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;
    final display = _user?.displayName;
    if (display == null || display.trim().isEmpty) {
      final email = _user?.email ?? '';
      _currentController.text = email.split('@').first;
    } else {
      _currentController.text = display;
    }
  }

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    super.dispose();
  }

  Future<void> _confirmChange() async {
    final newId = _newController.text.trim();
    if (newId.isEmpty) {
      showToast(message: 'Please enter a new User ID');
      return;
    }
    if (_user == null) {
      showToast(message: 'No user signed in');
      return;
    }

    setState(() => _saving = true);
    try {
      await _user!.updateDisplayName(newId);
      // Refresh local user object
      await FirebaseAuth.instance.currentUser?.reload();
      _user = FirebaseAuth.instance.currentUser;
      final display = _user?.displayName ?? '';
      _currentController.text = display;
      _newController.clear();
      showToast(message: 'User ID updated');
      Navigator.maybePop(context);
    } catch (e) {
      showToast(message: 'Failed to update User ID');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text('User ID'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              const Text(
                'Current User ID',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _currentController,
                readOnly: true,
                decoration: InputDecoration(
                  hintText: 'Current User ID',
                  filled: true,
                  fillColor: const Color(0xFFF3F3F5),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Colors.black38,
                      width: 1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Colors.black54,
                      width: 1,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'New User ID',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _newController,
                decoration: InputDecoration(
                  hintText: 'New User ID',
                  filled: true,
                  fillColor: const Color(0xFFF3F3F5),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Colors.black38,
                      width: 1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Colors.black54,
                      width: 1,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(bottom: 20.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _confirmChange,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    child: _saving
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Confirm',
                            style: TextStyle(fontSize: 18, color: Colors.white),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
