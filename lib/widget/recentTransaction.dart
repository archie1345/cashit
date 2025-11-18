import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:rxdart/rxdart.dart';

class RecentTransactions extends StatefulWidget {
  final int limit;
  final bool useDummyData;

  const RecentTransactions({
    super.key,
    required this.limit,
    this.useDummyData = false,
  });

  @override
  State<RecentTransactions> createState() => _RecentTransactionsState();
}

class _RecentTransactionsState extends State<RecentTransactions> {
  late Stream<List<Map<String, dynamic>>> _historyStream;
  final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _historyStream = _fetchRealtimeHistory();
  }

  Stream<List<Map<String, dynamic>>> _fetchRealtimeHistory() {
    if (widget.useDummyData) {
      return _getDummyHistoryStream();
    }
    
    final db = FirebaseFirestore.instance;
    if (currentUserId == null) {
      return Stream.value([]); // Return an empty stream if user is null
    }

    Stream<QuerySnapshot> sentStream = db
        .collection('transfer')
        .where('senderId', isEqualTo: currentUserId) 
        .orderBy('createdAt', descending: true)
        .limit(widget.limit)
        .snapshots();

    Stream<QuerySnapshot> receivedStream = db
        .collection('transfer')
        .where('recipientId', isEqualTo: currentUserId)
        .orderBy('createdAt', descending: true)
        .limit(widget.limit)
        .snapshots();

    Stream<QuerySnapshot> topupStream = db
        .collection('topup')
        .where('userId', isEqualTo: currentUserId)
        .orderBy('createdAt', descending: true)
        .limit(widget.limit)
        .snapshots();

    return Rx.combineLatest3(
      sentStream,
      receivedStream,
      topupStream,
      (QuerySnapshot sent, QuerySnapshot received, QuerySnapshot topups) {
        
        final allDocs = [
          ...sent.docs,
          ...received.docs,
          ...topups.docs,
        ];

        final Map<String, Map<String, dynamic>> uniqueDocs = {};
        for (var doc in allDocs) {
          uniqueDocs[doc.id] = doc.data() as Map<String, dynamic>;
        }

        final allTransactions = uniqueDocs.values.toList();

        allTransactions.sort((a, b) {
          Timestamp aTs = a['createdAt'] as Timestamp;
          Timestamp bTs = b['createdAt'] as Timestamp;
          return bTs.compareTo(aTs); // Newest first
        });

        return allTransactions;
      },
    );
  }

  Stream<List<Map<String, dynamic>>> _getDummyHistoryStream() async* {
    await Future.delayed(const Duration(milliseconds: 500));
    
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));
    final twoDaysAgo = now.subtract(const Duration(days: 2));
    
    if (currentUserId == null) {
      yield [];
      return;
    }

    yield [
      {
        'type': 'P2P_TRANSFER',
        'amount': 20000,
        'senderId': currentUserId,
        'recipientUsername': 'Ahmad Ibrahim',
        'createdAt': Timestamp.fromDate(now), // Use Timestamp
      },
      {
        'type': 'TOP-UP',
        'amount': 200000,
        'userId': currentUserId,
        'createdAt': Timestamp.fromDate(yesterday), // Use Timestamp
      },
      {
        'type': 'BILL_PAYMENT',
        'amount': 10000,
        'userId': currentUserId,
        'accountNumber': '...0451',
        'createdAt': Timestamp.fromDate(yesterday), // Use Timestamp
      },
      {
        'type': 'P2P_TRANSFER',
        'amount': 50000,
        'senderId': 'user-id-klarissa',
        'recipientId': currentUserId,
        'senderUsername': 'Klarissa',
        'createdAt': Timestamp.fromDate(twoDaysAgo), // Use Timestamp
      },
    ];
  }

  String _formatCurrency(int amount) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(amount);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(30)
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 15,
            offset: Offset(0, -5),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Text(
              'Recent Transactions',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<dynamic>>(
              stream: _historyStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  print("History Stream Error: ${snapshot.error}");
                  return Center(
                      child: Text('Error: ${snapshot.error}',
                          style: TextStyle(color: Colors.red)));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Text(
                      'No recent transactions found.',
                      style: GoogleFonts.poppins(
                          fontSize: 16, color: Colors.grey),
                    ),
                  );
                }

                final allTransactions = snapshot.data!;
                final recentTransactions =
                    allTransactions.take(widget.limit).toList();

                return ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: recentTransactions.length,
                  itemBuilder: (context, index) {
                    final transaction =
                        recentTransactions[index] as Map<String, dynamic>;
                    return _buildRecentTransactionTile(transaction);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTransactionTile(Map<String, dynamic> transaction) {
    final String currentUserId = FirebaseAuth.instance.currentUser!.uid;
    final String type = transaction['type'].toString().toUpperCase();
    final int amount = transaction['amount'] ?? 0;

    String title = 'Unknown Transaction';
    IconData iconData = Icons.person;
    Color amountColor = Colors.black;
    String amountDisplay = '';
    String dateDisplay = '';

    bool isSender = false;
    if (type == 'P2P_TRANSFER') {
      isSender = (transaction['senderId'] == currentUserId);
    } else if (type == 'WITHDRAWAL' || type == 'BILL_PAYMENT') {
      isSender = true;
    } else if (type == 'TOP-UP') {
      isSender = false;
    }

    final formattedAmount = _formatCurrency(amount);

    if (isSender) {
      amountDisplay = '- $formattedAmount';
      amountColor = Colors.red[700]!;
      if (type == 'P2P_TRANSFER') {
        title = 'Sent to @${transaction['recipientUsername'] ?? 'User'}';
        iconData = Icons.person_outline;
      } else if (type == 'BILL_PAYMENT') {
        title = 'Bill Payment (${transaction['accountNumber']})';
        iconData = Icons.receipt_long_outlined;
      } else {
        title = 'Withdrawal';
        iconData = Icons.account_balance_outlined;
      }
    } else {
      amountDisplay = '+ $formattedAmount';
      amountColor = Colors.green[700]!;
      if (type == 'P2P_TRANSFER') {
        title = 'Received from @${transaction['senderUsername'] ?? 'User'}';
        iconData = Icons.person_outline;
      } else {
        title = 'Top-Up from Bank';
        iconData = Icons.add_card_outlined;
      }
    }

    final Timestamp timestamp = transaction['createdAt'] as Timestamp;
    final DateTime date = timestamp.toDate();
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final checkDate = DateTime(date.year, date.month, date.day);

    if (checkDate == today) {
      dateDisplay = 'Today';
    } else if (checkDate == yesterday) {
      dateDisplay = 'Yesterday';
    } else {
      dateDisplay = DateFormat('dd/MM').format(date);
    }

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.grey[100],
        child: Icon(iconData, color: Colors.black87),
      ),
      title: Text(
        title,
        style: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 14),
      ),
      subtitle: Text(
        dateDisplay,
        style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
      ),
      trailing: Text(
        amountDisplay,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          color: amountColor,
          fontSize: 14,
        ),
      ),
    );
  }
}
