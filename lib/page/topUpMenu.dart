import 'package:cashit/page/topUp.dart';
import 'package:cashit/classes/colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TopUpMenuPage extends StatelessWidget {
  const TopUpMenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    // List of menu items
    final List<Map<String, dynamic>> menuItems = [
      {
        'label': 'Electricity',
        'icon': Icons.lightbulb_outline,
        'color': Colors.orange.shade100,
        'iconColor': Colors.orange,
        'page': const TopUpPage(
          title: 'Electricity Bill',
          icon: Icons.lightbulb_outline,
          color: Color(0xFFFFE0B2), // Orange[100]
          iconColor: Colors.orange,
          inputLabel: 'Meter Number / ID',
          placeholder: 'Enter 11-12 digit ID',
          billerStripeId: 'acct_1SW6MSKB847mXoXV',
        ),
      },
      {
        'label': 'Phone Credit',
        'icon': Icons.phone_android,
        'color': Colors.blue.shade100,
        'iconColor': Colors.blue,
        'page': const TopUpPage(
          title: 'Phone Credit',
          icon: Icons.phone_android,
          color: Color(0xFFBBDEFB), // Blue[100]
          iconColor: Colors.blue,
          inputLabel: 'Phone Number',
          placeholder: '08...',
          billerStripeId: 'acct_1SW6WZKB84mNMPPL',
        ),
      },
      {
        'label': 'Water (PDAM)',
        'icon': Icons.water_drop_outlined,
        'color': Colors.cyan.shade100,
        'iconColor': Colors.cyan,
        'page': const TopUpPage(
          title: 'Water Bill (PDAM)',
          icon: Icons.water_drop_outlined,
          color: Color(0xFFB2EBF2), // Cyan[100]
          iconColor: Colors.cyan,
          inputLabel: 'Customer ID',
          placeholder: 'Enter Customer ID',
          billerStripeId: 'acct_1SW6o6KB84Ogk67V',
        ),
      },
      {
        'label': 'Internet',
        'icon': Icons.wifi,
        'color': Colors.purple.shade100,
        'iconColor': Colors.purple,
        'page': const TopUpPage(
          title: 'Internet Bill',
          icon: Icons.wifi,
          color: Color(0xFFE1BEE7), // Purple[100]
          iconColor: Colors.purple,
          inputLabel: 'Account Number',
          placeholder: 'Enter Account No',
          billerStripeId: 'acct_1SW6jJKB842UpowN',
        ),
      },
      {
        'label': 'BPJS',
        'icon': Icons.health_and_safety_outlined,
        'color': Colors.green.shade100,
        'iconColor': Colors.green,
        'page': const TopUpPage(
          title: 'BPJS Kesehatan',
          icon: Icons.health_and_safety_outlined,
          color: Color(0xFFC8E6C9), // Green[100]
          iconColor: Colors.green,
          inputLabel: 'VA Number',
          placeholder: 'Enter Virtual Account',
          billerStripeId: 'acct_1SW6t8KB843Nnas6',
        ),
      },
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Top Up & Bills',
          style: GoogleFonts.poppins(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [ColorPalletes.pastelGreen, ColorPalletes.pastelpurple],
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
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose Service',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(20.0),
                itemCount: menuItems.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final item = menuItems[index];
                  return _buildListItem(context, item);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListItem(BuildContext context, Map<String, dynamic> item) {
    return GestureDetector(
      onTap: () {
        if (item['page'] != null) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => item['page']),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${item['label']} feature coming soon!')),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon Circle
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: item['color'],
                shape: BoxShape.circle,
              ),
              child: Icon(item['icon'], color: item['iconColor'], size: 24),
            ),
            const SizedBox(width: 16),

            // Label
            Expanded(
              child: Text(
                item['label'],
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ),

            // Arrow Icon
            Icon(Icons.chevron_right, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}
