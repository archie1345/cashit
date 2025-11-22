import 'package:cashit/widget/transactionDetail.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class TransactionTile extends StatelessWidget {
  final Map<String, dynamic> transaction;

  const TransactionTile({super.key, required this.transaction});

  String _formatCurrency(num amount) {
    return NumberFormat.currency(
      locale: 'en_US',
      symbol: '\$ ',
      decimalDigits: 2,
    ).format(amount / 100);
  }

  DateTime _parseDate(dynamic createdAt) {
    if (createdAt == null) return DateTime.now();
    try {
      if (createdAt is Timestamp) {
        return createdAt.toDate();
      } else if (createdAt is Map) {
        if (createdAt.containsKey('_seconds')) {
          final int seconds = createdAt['_seconds'];
          final int nanoseconds = createdAt['_nanoseconds'] ?? 0;
          return DateTime.fromMillisecondsSinceEpoch(
              seconds * 1000 + nanoseconds ~/ 1000000);
        }
      } else if (createdAt is String) {
        return DateTime.parse(createdAt);
      } else if (createdAt is int) {
        return DateTime.fromMillisecondsSinceEpoch(createdAt);
      }
    } catch (e) {
      print('Error parsing date: $e');
    }
    return DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final String type = (transaction['type'] ?? 'UNKNOWN').toString().toUpperCase();
    final int amount = transaction['amount'] ?? 0;
    final String status = (transaction['status'] ?? 'COMPLETED').toString().toUpperCase();

    String title = 'Unknown Transaction';
    String amountDisplay = '';
    IconData iconData = Icons.help_outline;
    Color amountColor = Colors.black;
    Color iconColor = Colors.black87;
    String dateDisplay = '';

    // --- STATUS LOGIC ---
    bool isFailed = status == 'FAILED';
    bool isCanceled = status == 'CANCELED';
    bool isExpired = status == 'EXPIRED';
    bool isPending = status == 'PENDING';
    bool isSuccess = status == 'COMPLETED' || status == 'SUCCESS';

    // --- SENDER/RECEIVER LOGIC ---
    bool isSender = false;
    if (type == 'P2P_TRANSFER') {
      isSender = (transaction['senderId'] == currentUserId);
    } else if (type == 'WITHDRAWAL' || 
               type == 'BILL_PAYMENT' || 
               type == 'BILL-PAYMENT') { // <--- ADDED BILL-PAYMENT CHECK
      isSender = true;
    } else if (type == 'TOP-UP' || type == 'TOPUP') {
      isSender = false;
    }

    // --- CONTENT LOGIC ---
    if (isSender) {
      amountDisplay = '- ${_formatCurrency(amount)}';
      amountColor = isSuccess ? Colors.red[700]! : Colors.grey;
      
      if (type == 'P2P_TRANSFER') {
        title = 'Sent to @${transaction['recipientUsername'] ?? 'User'}';
        iconData = Icons.arrow_outward_rounded;
      } else if (type.contains('BILL')) { // Catches BILL_PAYMENT and BILL-PAYMENT
        title = 'Bill Payment';
        iconData = Icons.receipt_long_rounded;
      } else {
        title = 'Withdrawal';
        iconData = Icons.account_balance_rounded;
      }
    } else {
      amountDisplay = '+ ${_formatCurrency(amount)}';
      amountColor = isSuccess ? Colors.green[700]! : Colors.grey;

      if (type == 'P2P_TRANSFER') {
        title = 'Received from @${transaction['senderUsername'] ?? 'User'}';
        iconData = Icons.arrow_downward_rounded;
      } else {
        title = 'Wallet Top-Up';
        iconData = Icons.add_card_rounded;
      }
    }

    // --- OVERRIDE UI BASED ON STATUS ---
    if (isExpired) {
      title = '$title (Expired)';
      iconData = Icons.timer_off_outlined;
      iconColor = Colors.grey;
      amountColor = Colors.grey;
    } else if (isCanceled) {
      title = '$title (Canceled)';
      iconData = Icons.cancel_outlined;
      iconColor = Colors.redAccent;
      amountColor = Colors.grey;
    } else if (isFailed) {
      title = '$title (Failed)';
      iconData = Icons.error_outline;
      iconColor = Colors.red;
    } else if (isPending) {
      title = '$title (Pending)';
      iconData = Icons.hourglass_empty_rounded;
      iconColor = Colors.orange;
      amountColor = Colors.orange;
    }

    final DateTime date = _parseDate(transaction['createdAt']);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final checkDate = DateTime(date.year, date.month, date.day);

    if (checkDate == today) {
      dateDisplay = 'Today, ${DateFormat('HH:mm').format(date)}';
    } else if (checkDate == yesterday) {
      dateDisplay = 'Yesterday, ${DateFormat('HH:mm').format(date)}';
    } else {
      dateDisplay = DateFormat('dd MMM, HH:mm').format(date);
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TransactionDetailPage(transaction: transaction),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4.0),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.8),
          borderRadius: BorderRadius.circular(15),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: CircleAvatar(
            backgroundColor: Colors.white.withOpacity(0.8),
            child: Icon(iconData, color: iconColor),
          ),
          title: Text(
            title,
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black87),
          ),
          subtitle: Text(
            dateDisplay,
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.black54),
          ),
          trailing: Text(
            amountDisplay,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              color: amountColor,
              fontSize: 14,
              decoration: (isExpired || isCanceled || isFailed) 
                  ? TextDecoration.lineThrough
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}