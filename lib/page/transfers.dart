import 'package:cashit/widget/bottom_nav.dart';
import 'package:flutter/material.dart';
import 'package:cashit/page/home.dart';
import 'package:cashit/page/profile.dart';
import 'package:cashit/page/addRecipient.dart';
import 'package:cashit/page/transferDetails.dart';
import 'package:google_fonts/google_fonts.dart';

class TransfersPage extends StatefulWidget {
  const TransfersPage({Key? key}) : super(key: key);

  @override
  State<TransfersPage> createState() => _TransfersPageState();
}

class _TransfersPageState extends State<TransfersPage> {
  List<Map<String, String>> recipients = [];
  Map<String, String>? _selectedRecipient;

  @override
  void initState() {
    super.initState();
    // Initialize with empty recipients list
    recipients = [];
  }

  void _openAddRecipientPage() async {
    final result = await Navigator.push<Map<String, String>>(
      context,
      MaterialPageRoute(builder: (_) => const AddRecipientPage()),
    );

    if (result != null) {
      setState(() {
        recipients.add(result);
      });
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
      if (idx == 1) return; // already on Transfers
      if (idx == 2)
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ProfilePage()),
        );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: BottomNavBar(currentIndex: 1, onTap: _onTap),
      body: SafeArea(
        child: Column(
          children: [
            // Header with gradient and back arrow
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                vertical: 16.0,
                horizontal: 16.0,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green.shade200, Colors.purple.shade200],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black87),
                    onPressed: () {
                      // Navigate back to Home using bottom nav
                      _onTap(0);
                    },
                  ),
                  Expanded(
                    child: Text(
                      'Transfer',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            // Content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  // "Send to" label
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

                  // Add New button
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

                  // Recipients list
                  ...recipients.map((recipient) {
                    final isSelected = _selectedRecipient == recipient;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedRecipient = recipient;
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
                            ),
                            const SizedBox(width: 16.0),
                            Text(
                              recipient['name']!,
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                            if (isSelected) const Spacer(),
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
              ),
            ),

            // Select Recipient button
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
