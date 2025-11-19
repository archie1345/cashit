import 'dart:convert';
import 'package:cashit/widget/transactionTileBuilder.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cashit/classes/colors.dart';

enum FilterType { all, transfer, topup }

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final String baseUrl = "https://api-cksvvgpqtq-uc.a.run.app";
  late Future<List<dynamic>> _historyFuture;

  FilterType _selectedFilter = FilterType.all;

  static const pastelGreen = ColorPalletes.pastelGreen;
  static const pastelpurple = ColorPalletes.pastelpurple;
  static const pastelPink = ColorPalletes.pastelPink;

  @override
  void initState() {
    super.initState();
    _historyFuture = _fetchHistory();
  }

  Future<List<dynamic>> _fetchHistory() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not logged in.');
    }

    final idToken = await user.getIdToken(true);
    final response = await http.get(
      Uri.parse('$baseUrl/api/transaction-history'),
      headers: {
        'Authorization': 'Bearer $idToken',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['transactions'] as List<dynamic>;
    } else {
      throw Exception('Failed to load history: ${response.body}');
    }
  }

  // Robust date parsing for sorting
  DateTime _parseDate(dynamic createdAt) {
    if (createdAt == null) return DateTime.now();
    try {
      if (createdAt is Map && createdAt.containsKey('_seconds')) {
        final int seconds = createdAt['_seconds'];
        final int nanoseconds = createdAt['_nanoseconds'] ?? 0;
        return DateTime.fromMillisecondsSinceEpoch(
            seconds * 1000 + nanoseconds ~/ 1000000);
      } else if (createdAt is String) {
        return DateTime.parse(createdAt);
      } else if (createdAt is int) {
        return DateTime.fromMillisecondsSinceEpoch(createdAt);
      }
    } catch (e) {
      // ignore error
    }
    return DateTime.now();
  }

  Map<DateTime, List<dynamic>> _groupTransactionsByDay(
      List<dynamic> transactions) {
    final Map<DateTime, List<dynamic>> grouped = {};

    for (final tx in transactions) {
      final DateTime date = _parseDate(tx['createdAt']);
      final DateTime dayKey = DateTime(date.year, date.month, date.day);

      if (grouped[dayKey] == null) {
        grouped[dayKey] = [];
      }
      grouped[dayKey]!.add(tx);
    }
    return grouped;
  }

  List<dynamic> _applyFilter(List<dynamic> allTransactions) {
    switch (_selectedFilter) {
      case FilterType.transfer:
        return allTransactions
            .where((t) => t['type'] == 'P2P_TRANSFER')
            .toList();
      case FilterType.topup:
        return allTransactions
            .where((t) => t['type'] != 'P2P_TRANSFER')
            .toList();
      case FilterType.all:
        return allTransactions;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [pastelGreen, pastelpurple, pastelPink],
                stops: const [0.1, 0.5, 1.0],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 16.0),
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          pastelGreen.withOpacity(0.8),
                          pastelpurple.withOpacity(0.8),
                        ],
                      ),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        )
                      ]),
                  child: Row(
                    children: [
                      IconButton(
                        icon:
                            const Icon(Icons.arrow_back, color: Colors.black87),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      Expanded(
                        child: Text(
                          'History',
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
                
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: SegmentedButton<FilterType>(
                    style: SegmentedButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.2),
                      foregroundColor: Colors.black,
                      selectedForegroundColor: Colors.white,
                      selectedBackgroundColor: pastelpurple.withOpacity(0.8),
                    ),
                    segments: const [
                      ButtonSegment(
                        value: FilterType.all,
                        label: Text('All'),
                        icon: Icon(Icons.list),
                      ),
                      ButtonSegment(
                        value: FilterType.transfer,
                        label: Text('Transfers'),
                        icon: Icon(Icons.swap_horiz),
                      ),
                      ButtonSegment(
                        value: FilterType.topup,
                        label: Text('Top-ups'),
                        icon: Icon(Icons.add_card),
                      ),
                    ],
                    selected: {_selectedFilter},
                    onSelectionChanged: (Set<FilterType> newSelection) {
                      setState(() {
                        _selectedFilter = newSelection.first;
                      });
                    },
                  ),
                ),

                Expanded(
                  child: FutureBuilder<List<dynamic>>(
                    future: _historyFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              'Error loading history: ${snapshot.error}',
                              style: GoogleFonts.poppins(color: Colors.red),
                            ),
                          ),
                        );
                      }

                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Center(
                          child: Text(
                            'No transactions found.',
                            style: GoogleFonts.poppins(
                                fontSize: 18, color: Colors.grey),
                          ),
                        );
                      }

                      final allTransactions = snapshot.data!;
                      final filteredTransactions =
                          _applyFilter(allTransactions);
                      
                      if (filteredTransactions.isEmpty) {
                         return Center(
                          child: Text(
                            'No transactions found for this filter.',
                            style: GoogleFonts.poppins(
                                fontSize: 16, color: Colors.grey[700]),
                          ),
                        );
                      }

                      final groupedTransactions =
                          _groupTransactionsByDay(filteredTransactions);
                      final sortedDates = groupedTransactions.keys.toList()
                        ..sort((a, b) => b.compareTo(a)); 

                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        itemCount: sortedDates.length,
                        itemBuilder: (context, index) {
                          final dateKey = sortedDates[index];
                          final transactionsForDay =
                              groupedTransactions[dateKey]!;

                          final String dateHeader =
                              DateFormat('EEEE, d MMM yyyy').format(dateKey);

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(
                                    top: 16.0, bottom: 8.0, left: 8.0),
                                child: Text(
                                  dateHeader,
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                              // Use the new Reusable TransactionTile
                              ...transactionsForDay
                                  .map((tx) => TransactionTile(
                                      transaction: tx as Map<String, dynamic>))
                                  .toList(),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}