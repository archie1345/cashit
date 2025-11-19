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
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(amount);
  }

  // Robust date parser to handle API (Map/String) and Firestore (Timestamp)
  DateTime _parseDate(dynamic createdAt) {
    if (createdAt == null) return DateTime.now();

    try {
      if (createdAt is Timestamp) {
        return createdAt.toDate();
      } else if (createdAt is Map) {
        // Handle {_seconds: 123, _nanoseconds: 123} format from API
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

    String title = 'Unknown Transaction';
    String amountDisplay = '';
    IconData iconData = Icons.person_outline;
    Color amountColor = Colors.black;
    String dateDisplay = '';

    // Determine Sender/Receiver logic
    bool isSender = false;
    if (type == 'P2P_TRANSFER') {
      // Check both senderId fields for compatibility
      isSender = (transaction['senderId'] == currentUserId);
    } else if (type == 'WITHDRAWAL' || type == 'BILL_PAYMENT') {
      isSender = true;
    } else if (type == 'TOP-UP') {
      isSender = false;
    }

    if (isSender) {
      amountDisplay = '- ${_formatCurrency(amount)}';
      amountColor = Colors.red[700]!;
      if (type == 'P2P_TRANSFER') {
        title = 'Sent to @${transaction['recipientUsername'] ?? 'User'}';
        iconData = Icons.arrow_outward_rounded;
      } else if (type == 'BILL_PAYMENT') {
        title = 'Bill Payment (${transaction['accountNumber'] ?? '...'})';
        iconData = Icons.receipt_long_rounded;
      } else {
        title = 'Withdrawal';
        iconData = Icons.account_balance_rounded;
      }
    } else {
      amountDisplay = '+ ${_formatCurrency(amount)}';
      amountColor = Colors.green[700]!;
      if (type == 'P2P_TRANSFER') {
        title = 'Received from @${transaction['senderUsername'] ?? 'User'}';
        iconData = Icons.arrow_downward_rounded;
      } else {
        title = 'Top-Up from Bank';
        iconData = Icons.add_card_rounded;
      }
    }

    // Date Formatting Logic
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
          color: Colors.white.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(15),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: CircleAvatar(
            backgroundColor: Colors.white.withOpacity(0.8),
            child: Icon(iconData, color: Colors.black87),
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
            ),
          ),
        ),
      ),
    );
  }
}