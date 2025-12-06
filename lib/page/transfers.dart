import 'package:cashit/widget/bottom_nav.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cashit/page/home.dart';
import 'package:cashit/page/profile.dart';
import 'package:cashit/page/addRecipient.dart';
import 'package:cashit/widget/transferDetails.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cashit/classes/colors.dart' as color;

class TransfersPage extends StatefulWidget {
  const TransfersPage({Key? key}) : super(key: key);

  @override
  State<TransfersPage> createState() => _TransfersPageState();
}

class _TransfersPageState extends State<TransfersPage> {
  // We don't need a local list anymore, we use Firestore
  Map<String, dynamic>? _selectedRecipient;

  void _openAddRecipientPage() async {
    //Wait for data from Add Page
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (_) => const AddRecipientPage()),
    );

    //Save to Firestore
    if (result != null) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('saved_recipients')
            .doc(result['uid']) // Use UID to avoid duplicates
            .set(result);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    void _onTap(int idx) {
      if (idx == 0)
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const Homepage()),
        );
      if (idx == 1) return;
      if (idx == 2)
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ProfilePage()),
        );
    }

    final user = FirebaseAuth.instance.currentUser;
    final pastelGreen = color.ColorPalletes.pastelGreen;
    final pastelPurple = color.ColorPalletes.pastelpurple;

    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: BottomNavBar(currentIndex: 1, onTap: _onTap),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: AppBar(
          title: Text(
            'Transfer',
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
            onPressed: () => _onTap(0),
          ),
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [pastelGreen, pastelPurple],
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
            // Content
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(user?.uid)
                    .collection('saved_recipients')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final recipients = snapshot.data!.docs;

                  return ListView(
                    padding: const EdgeInsets.all(16.0),
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0, bottom: 12.0),
                        child: Text(
                          'Send to',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ),

                      // Add New Button
                      GestureDetector(
                        onTap: _openAddRecipientPage,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12.0),
                          padding: const EdgeInsets.all(12.0),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.green.shade400,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 28,
                                backgroundColor: Colors.green.shade100,
                                child: Icon(
                                  Icons.add,
                                  color: Colors.green.shade400,
                                  size: 32,
                                ),
                              ),
                              const SizedBox(width: 16.0),
                              Text(
                                'Add New',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Recipients List from Firestore
                      ...recipients.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final isSelected =
                            _selectedRecipient != null &&
                            _selectedRecipient!['uid'] == data['uid'];

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedRecipient = data;
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12.0),
                            padding: const EdgeInsets.all(12.0),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: isSelected
                                    ? Colors.blue.shade400
                                    : Colors.grey.shade300,
                                width: isSelected ? 2 : 1,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              color: isSelected
                                  ? Colors.blue.shade50
                                  : Colors.transparent,
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 28,
                                  backgroundColor: Colors.grey.shade200,
                                  child: Text(
                                    (data['name'] ?? 'U')[0].toUpperCase(),
                                  ),
                                ),
                                const SizedBox(width: 16.0),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        data['name'] ?? 'Unknown',
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      Text(
                                        '@${data['username']}',
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  Icon(
                                    Icons.check_circle,
                                    color: Colors.blue.shade400,
                                  ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),

                      const SizedBox(height: 24.0),
                    ],
                  );
                },
              ),
            ),

            // Select Button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selectedRecipient != null
                      ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TransferDetailsPage(
                                recipient: _selectedRecipient!,
                              ),
                            ),
                          );
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedRecipient != null
                        ? Colors.black
                        : Colors.grey.shade400,
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Select Recipient',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
