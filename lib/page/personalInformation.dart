import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cashit/widget/toast.dart';
import 'package:cashit/classes/colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

// Personal Information edit page: load from Firestore and allow updates

class PersonalInformationPage extends StatefulWidget {
  const PersonalInformationPage({Key? key}) : super(key: key);

  @override
  State<PersonalInformationPage> createState() =>
      _PersonalInformationPageState();
}

class _PersonalInformationPageState extends State<PersonalInformationPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nikController = TextEditingController();
  final TextEditingController _birthplaceController = TextEditingController();
  final TextEditingController _birthdateController = TextEditingController();
  final TextEditingController _religionController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  bool _loading = true;
  bool _saving = false;
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  @override
  void dispose() {
    _nikController.dispose();
    _birthplaceController.dispose();
    _birthdateController.dispose();
    _religionController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadUserInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      showToast(message: 'No user signed in');
      setState(() => _loading = false);
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (!doc.exists) {
        setState(() => _loading = false);
        return;
      }
      final data = doc.data() as Map<String, dynamic>;
      _nikController.text = (data['nik'] ?? '').toString();
      _birthplaceController.text = (data['birthLocation'] ?? '').toString();
      final birthDateVal = data['birthDate'];
      if (birthDateVal != null) {
        // Handle both timestamp and string
        if (birthDateVal is Timestamp) {
          _birthdateController.text = _dateFormat.format(birthDateVal.toDate());
        } else if (birthDateVal is String) {
          _birthdateController.text = birthDateVal;
        }
      }
      _religionController.text = (data['religion'] ?? '').toString();
      _addressController.text = (data['address'] ?? '').toString();
    } catch (e) {
      showToast(message: 'Failed to load personal information');
      debugPrint('Load personal info error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickBirthDate() async {
    DateTime initial = DateTime.now();
    try {
      final parts = _birthdateController.text.split('/');
      if (parts.length == 3) {
        final d = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        final y = int.tryParse(parts[2]);
        if (d != null && m != null && y != null) initial = DateTime(y, m, d);
      }
    } catch (_) {}

    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      _birthdateController.text = _dateFormat.format(date);
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      showToast(message: 'No user signed in');
      return;
    }

    setState(() => _saving = true);
    try {
      final Map<String, dynamic> payload = {
        'nik': _nikController.text.trim(),
        'birthLocation': _birthplaceController.text.trim(),
        'birthDate': _birthdateController.text.trim(),
        'religion': _religionController.text.trim(),
        'address': _addressController.text.trim(),
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(payload, SetOptions(merge: true));
      showToast(message: 'Personal information updated');
      Navigator.maybePop(context);
    } catch (e) {
      debugPrint('Save personal info error: $e');
      showToast(message: 'Failed to save personal information');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _buildField({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        child,
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 500),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: AppBar(
            title: Text(
              'Personal Information',
              style: GoogleFonts.poppins(
                color: Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black87),
              onPressed: () => Navigator.maybePop(context),
            ),
            flexibleSpace: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    ColorPalletes.pastelGreen,
                    ColorPalletes.pastelpurple,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
            ),
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 18),
                              Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    children: [
                                      _buildField(
                                        label: 'Nomor Induk Kependudukan (NIK)',
                                        child: TextFormField(
                                          controller: _nikController,
                                          decoration: InputDecoration(
                                            hintText: 'NIK',
                                            filled: true,
                                            fillColor: const Color(0xFFF3F3F5),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: const BorderSide(
                                                color: Colors.black38,
                                                width: 1,
                                              ),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: const BorderSide(
                                                color: Colors.black54,
                                                width: 1,
                                              ),
                                            ),
                                          ),
                                          keyboardType: TextInputType.number,
                                          validator: (s) =>
                                              (s != null && s.trim().isNotEmpty)
                                              ? null
                                              : 'Please enter NIK',
                                        ),
                                      ),

                                      _buildField(
                                        label: 'Birthplace',
                                        child: TextFormField(
                                          controller: _birthplaceController,
                                          decoration: InputDecoration(
                                            hintText: 'Birthplace',
                                            filled: true,
                                            fillColor: const Color(0xFFF3F3F5),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: const BorderSide(
                                                color: Colors.black38,
                                                width: 1,
                                              ),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: const BorderSide(
                                                color: Colors.black54,
                                                width: 1,
                                              ),
                                            ),
                                          ),
                                          validator: (s) =>
                                              (s != null && s.trim().isNotEmpty)
                                              ? null
                                              : 'Please enter birthplace',
                                        ),
                                      ),

                                      _buildField(
                                        label: 'Birthdate',
                                        child: TextFormField(
                                          controller: _birthdateController,
                                          readOnly: true,
                                          onTap: _pickBirthDate,
                                          decoration: InputDecoration(
                                            hintText: 'dd/mm/yyyy',
                                            filled: true,
                                            fillColor: const Color(0xFFF3F3F5),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: const BorderSide(
                                                color: Colors.black38,
                                                width: 1,
                                              ),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: const BorderSide(
                                                color: Colors.black54,
                                                width: 1,
                                              ),
                                            ),
                                          ),
                                          validator: (s) =>
                                              (s != null && s.trim().isNotEmpty)
                                              ? null
                                              : 'Please select birthdate',
                                        ),
                                      ),

                                      _buildField(
                                        label: 'Religion',
                                        child: TextFormField(
                                          controller: _religionController,
                                          decoration: InputDecoration(
                                            hintText: 'Religion',
                                            filled: true,
                                            fillColor: const Color(0xFFF3F3F5),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: const BorderSide(
                                                color: Colors.black38,
                                                width: 1,
                                              ),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: const BorderSide(
                                                color: Colors.black54,
                                                width: 1,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),

                                      _buildField(
                                        label: 'Address',
                                        child: TextFormField(
                                          controller: _addressController,
                                          minLines: 1,
                                          maxLines: 3,
                                          decoration: InputDecoration(
                                            hintText: 'Address',
                                            filled: true,
                                            fillColor: const Color(0xFFF3F3F5),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: const BorderSide(
                                                color: Colors.black38,
                                                width: 1,
                                              ),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: const BorderSide(
                                                color: Colors.black54,
                                                width: 1,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(height: 18),
                              const Spacer(),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 20.0),
                                child: SizedBox(
                                  width: double.infinity,
                                  height: 56,
                                  child: ElevatedButton(
                                    onPressed: _saving ? null : _save,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.black,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: _saving
                                        ? const CircularProgressIndicator(
                                            color: Colors.white,
                                          )
                                        : Text(
                                            'Confirm',
                                            style: GoogleFonts.poppins(
                                              fontSize: 18,
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                            ],
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
