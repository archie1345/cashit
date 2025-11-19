import 'package:cashit/classes/colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class TransactionDetailPage extends StatelessWidget {
  final Map<String, dynamic> transaction;
  static const pastelGreen = ColorPalletes.pastelGreen;
  static const pastelpurple = ColorPalletes.pastelpurple;
  static const pastelPink = ColorPalletes.pastelPink;

  const TransactionDetailPage({super.key, required this.transaction});

  String _formatCurrency(num amount) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(amount);
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'Unknown Date';
    
    DateTime dateTime;
    try {
      if (date is Timestamp) {
        dateTime = date.toDate();
      } else if (date is String) {
        dateTime = DateTime.parse(date);
      } else if (date is int) {
         dateTime = DateTime.fromMillisecondsSinceEpoch(date);
      } else {
        return 'Unknown Date';
      }
      return DateFormat('d MMM yyyy, HH:mm').format(dateTime);
    } catch (e) {
      return 'Invalid Date';
    }
  }

  @override
  Widget build(BuildContext context) {
    final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final String type = (transaction['type'] ?? 'UNKNOWN').toString().toUpperCase();
    final int amount = transaction['amount'] ?? 0;
    final String status = (transaction['status'] ?? 'COMPLETED').toString().toUpperCase();
    
    // --- UI Logic based on Transaction Type ---
    String title = 'Transaction';
    IconData icon = Icons.receipt;
    Color color = Colors.black;
    bool isNegative = false;
    String counterPartyLabel = 'Details';
    String counterPartyValue = '-';

    if (type == 'P2P_TRANSFER') {
      // Check if we are the sender or receiver
      // Note: Your API uses 'senderId', Firestore uses 'senderId'.
      if (transaction['senderId'] == currentUserId) {
        title = 'Transfer Sent';
        icon = Icons.arrow_outward_rounded;
        color = Colors.red;
        isNegative = true;
        counterPartyLabel = 'To';
        counterPartyValue = '@${transaction['recipientUsername'] ?? 'User'}';
      } else {
        title = 'Transfer Received';
        icon = Icons.arrow_downward_rounded;
        color = Colors.green;
        isNegative = false;
        counterPartyLabel = 'From';
        counterPartyValue = '@${transaction['senderUsername'] ?? 'User'}';
      }
    } else if (type == 'TOP-UP') {
      title = 'Top Up';
      icon = Icons.add_card_rounded;
      color = Colors.green;
      isNegative = false;
      counterPartyLabel = 'Method';
      counterPartyValue = 'Stripe / Bank';
    } else if (type == 'WITHDRAWAL') {
      title = 'Withdrawal';
      icon = Icons.account_balance_rounded;
      color = Colors.red;
      isNegative = true;
      counterPartyLabel = 'Destination';
      counterPartyValue = 'Bank Account';
    } else if (type == 'BILL_PAYMENT') {
      title = 'Bill Payment';
      icon = Icons.receipt_long_rounded;
      color = Colors.red;
      isNegative = true;
      counterPartyLabel = 'Biller Account';
      counterPartyValue = transaction['accountNumber'] ?? transaction['billerAccountId'] ?? '-';
    }

    final amountString = isNegative 
        ? '- ${_formatCurrency(amount)}' 
        : '+ ${_formatCurrency(amount)}';

    final statusColor = status == 'COMPLETED' || status == 'SUCCESS' || status == 'SUCCEEDED'
        ? Colors.green 
        : (status == 'PENDING' ? Colors.orange : Colors.red);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Details',
          style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 10),
            // --- Icon Circle ---
            Container(
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  )
                ],
              ),
              child: Icon(icon, size: 50, color: color),
            ),
            
            const SizedBox(height: 24),
            
            // --- Title & Amount ---
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              amountString,
              style: GoogleFonts.poppins(
                fontSize: 32,
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 12),
            
            // --- Status Badge ---
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                status,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: statusColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            const SizedBox(height: 40),

            // --- Details Card ---
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  )
                ],
              ),
              child: Column(
                children: [
                  _buildDetailRow('Date', _formatDate(transaction['createdAt'])),
                  const Divider(height: 30),
                  _buildDetailRow(counterPartyLabel, counterPartyValue),
                  const Divider(height: 30),
                  _buildDetailRow(
                    'Transaction ID', 
                    transaction['id'] ?? transaction['transactionId'] ?? 'N/A', 
                    isCopyable: true, 
                    context: context
                  ),
                  
                  if (transaction['gatewayTransactionId'] != null) ...[
                    const Divider(height: 30),
                    _buildDetailRow(
                      'Ref ID', 
                      transaction['gatewayTransactionId'], 
                      isSmall: true
                    ),
                  ]
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isCopyable = false, BuildContext? context, bool isSmall = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.grey[500],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  value,
                  textAlign: TextAlign.right,
                  style: GoogleFonts.poppins(
                    fontSize: isSmall ? 12 : 14,
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isCopyable && context != null) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: value));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Copied $label', style: GoogleFonts.poppins()),
                        duration: const Duration(seconds: 1),
                        backgroundColor: Colors.black87,
                      ),
                    );
                  },
                  child: const Icon(Icons.copy_rounded, size: 16, color: Colors.grey),
                )
              ]
            ],
          ),
        ),
      ],
    );
  }
}