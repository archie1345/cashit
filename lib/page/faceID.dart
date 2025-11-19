import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cashit/classes/colors.dart';
import 'package:cashit/widget/toast.dart';

class FaceIDPage extends StatefulWidget {
  const FaceIDPage({Key? key}) : super(key: key);

  @override
  State<FaceIDPage> createState() => _FaceIDPageState();
}

class _FaceIDPageState extends State<FaceIDPage> {
  bool _enabled = false;

  void _toggleEnabled(bool v) {
    setState(() => _enabled = v);
    showToast(message: _enabled ? 'Face ID enabled' : 'Face ID disabled');
  }

  void _onSetTap() {
    // simple effect: ripple handled by InkWell, show toast
    showToast(message: 'Set Face ID tapped');
  }

  @override
  Widget build(BuildContext context) {
    final pastelGreen = ColorPalletes.pastelGreen;
    final pastelPurple = ColorPalletes.pastelpurple;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 500),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                height: 120,
                width: double.infinity,
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
                child: Align(
                  alignment: Alignment.topLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.maybePop(context),
                  ),
                ),
              ),

              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 18),
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            children: [
                              // Face ID row with switch
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Face ID',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  // Custom switch look: use Switch with color customizations
                                  Switch(
                                    value: _enabled,
                                    onChanged: _toggleEnabled,
                                    activeColor: Colors.white,
                                    activeTrackColor: Colors.green.shade400,
                                    inactiveThumbColor: Colors.black,
                                    inactiveTrackColor: Colors.grey.shade300,
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ],
                              ),
                              const Divider(height: 24),

                              // Set Face ID row
                              InkWell(
                                onTap: _onSetTap,
                                borderRadius: BorderRadius.circular(4),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12.0,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Set Face ID',
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                        ),
                                      ),
                                      const Icon(Icons.chevron_right),
                                    ],
                                  ),
                                ),
                              ),
                              const Divider(height: 1),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),

                      const Spacer(),

                      // Confirm button
                      Padding(
                        padding: const EdgeInsets.only(bottom: 20.0),
                        child: SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: () {
                              showToast(message: 'Face ID settings saved');
                              Navigator.maybePop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28),
                              ),
                            ),
                            child: const Text(
                              'Confirm',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
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
