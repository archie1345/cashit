import 'dart:convert';
import 'package:cashit/widget/transactionTileBuilder.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cashit/classes/colors.dart';

enum FilterType { all, transfer, topup, withdrawal, electricity, water, internet, phoneCredit, health ,other }
enum TransactionDirection { all, moneyIn, moneyOut }

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final String baseUrl = "https://api-cksvvgpqtq-uc.a.run.app";
  late Future<List<dynamic>> _historyFuture;

  FilterType _selectedFilter = FilterType.all;
  TransactionDirection _selectedDirection = TransactionDirection.all;

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
      headers: {'Authorization': 'Bearer $idToken'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['transactions'] as List<dynamic>;
    } else {
      throw Exception('Failed to load history: ${response.body}');
    }
  }

  DateTime _parseDate(dynamic createdAt) {
    if (createdAt == null) return DateTime.now();
    try {
      if (createdAt is Map && createdAt.containsKey('_seconds')) {
        final int seconds = createdAt['_seconds'];
        final int nanoseconds = createdAt['_nanoseconds'] ?? 0;
        return DateTime.fromMillisecondsSinceEpoch(
          seconds * 1000 + nanoseconds ~/ 1000000,
        );
      } else if (createdAt is String) {
        return DateTime.parse(createdAt);
      } else if (createdAt is int) {
        return DateTime.fromMillisecondsSinceEpoch(createdAt);
      }
    } catch (e) {
    }
    return DateTime.now();
  }

  Map<DateTime, List<dynamic>> _groupTransactionsByDay(
    List<dynamic> transactions,
  ) {
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
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return [];

    return allTransactions.where((tx) {
      final type = tx['type'].toString().toUpperCase();
      final billType = tx['billType']?.toString().toUpperCase() ?? '';

      if (_selectedDirection != TransactionDirection.all) {
        bool isMoneyOut = false;
        
        if (type == 'P2P_TRANSFER') {
          isMoneyOut = (tx['senderId'] == currentUserId);
        } else if (type == 'WITHDRAWAL' || type == 'BILL-PAYMENT') {
          isMoneyOut = true;
        } else if (type == 'TOP-UP') {
          isMoneyOut = false;
        }

        if (_selectedDirection == TransactionDirection.moneyIn && isMoneyOut) {
          return false;
        }
        if (_selectedDirection == TransactionDirection.moneyOut && !isMoneyOut) {
          return false;
        }
      }

      if (_selectedFilter == FilterType.all) return true;

      switch (_selectedFilter) {
        case FilterType.transfer:
          return type == 'P2P_TRANSFER';
        case FilterType.topup:
          return type == 'TOP-UP' || type == 'BILL-PAYMENT';
        case FilterType.withdrawal:
          return type == 'WITHDRAWAL';
        case FilterType.electricity:
          return type == 'BILL-PAYMENT' && billType == 'ELECTRICITY';
        case FilterType.water:
          return type == 'BILL-PAYMENT' && billType == 'WATER';
        case FilterType.internet:
          return type == 'BILL-PAYMENT' && billType == 'INTERNET';
        case FilterType.phoneCredit:
          return type == 'BILL-PAYMENT' && billType == 'PHONECREDIT';
        case FilterType.health:
          return type == 'BILL-PAYMENT' && billType == 'HEALTH';
        // case FilterType.other:
        //   return type == 'BILL-PAYMENT' && !['electricity', 'phoneCredit', 'health', 'water', 'internet'].contains(billType);
        default:
          return true;
      }
    }).toList();
  }

  Widget _buildFilterChip(String label, FilterType type) {
    final bool isSelected = _selectedFilter == type;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: InkWell(
          onTap: () {
             setState(() {
               _selectedFilter = type;
             });
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
             padding: const EdgeInsets.symmetric(vertical: 8),
             decoration: BoxDecoration(
               color: isSelected ? Colors.black87 : Colors.white.withOpacity(0.5),
               borderRadius: BorderRadius.circular(20),
               border: Border.all(color: Colors.transparent),
             ),
             child: Text(
               label,
               textAlign: TextAlign.center,
               style: GoogleFonts.poppins(
                 fontSize: 12, 
                 fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                 color: isSelected ? Colors.white : Colors.black87
               ),
             ),
          ),
        ),
      ),
    );
  }

  void _showExtraFilters(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder( // Use StatefulBuilder to update state inside bottom sheet if needed
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Transaction Direction", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _buildDirectionChoice('All', TransactionDirection.all),
                      _buildDirectionChoice('Money In (+)', TransactionDirection.moneyIn),
                      _buildDirectionChoice('Money Out (-)', TransactionDirection.moneyOut),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text("Categories", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _buildExtraFilterChoice('Withdrawal', FilterType.withdrawal),
                      _buildExtraFilterChoice('Electricity', FilterType.electricity),
                      _buildExtraFilterChoice('Water', FilterType.water),
                      _buildExtraFilterChoice('Internet', FilterType.internet),
                      _buildExtraFilterChoice('Health', FilterType.health),

                    ],
                  ),
                ],
              ),
            );
          }
        );
      },
    );
  }

  Widget _buildExtraFilterChoice(String label, FilterType type) {
    final bool isSelected = _selectedFilter == type;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (bool selected) {
        setState(() {
          _selectedFilter = selected ? type : FilterType.all;
        });
        Navigator.pop(context); // Close the bottom sheet
      },
      selectedColor: pastelpurple,
      labelStyle: GoogleFonts.poppins(
        color: isSelected ? Colors.white : Colors.black87,
      ),
    );
  }

  Widget _buildDirectionChoice(String label, TransactionDirection direction) {
    final bool isSelected = _selectedDirection == direction;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (bool selected) {
        setState(() {
          // If tapping the same one, do nothing (keep it selected), or reset to All? 
          // Usually direction filters act like radio buttons, so just set it.
           _selectedDirection = direction;
        });
        Navigator.pop(context); 
      },
      selectedColor: pastelpurple,
      labelStyle: GoogleFonts.poppins(
        color: isSelected ? Colors.white : Colors.black87,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Check if one of the "Main" filters is active
    bool isMainFilterActive = [FilterType.all, FilterType.transfer, FilterType.topup].contains(_selectedFilter);
    // If not main, then an extra filter must be active
    bool isExtraFilterActive = !isMainFilterActive;
    
    String extraLabel = "";
    if(isExtraFilterActive) {
       extraLabel = _selectedFilter.name[0].toUpperCase() + _selectedFilter.name.substring(1); 
    }

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [pastelGreen, pastelpurple, pastelPink],
                stops: [0.1, 0.5, 1.0],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Custom AppBar
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.only(left: 8.0, right: 8.0, bottom: 8.0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.black87),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      Expanded(
                        child: Text(
                          'History',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
                
                // --- Simplified Category Filters (Direction filter moved to popup) ---
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    children: [
                      _buildFilterChip('All', FilterType.all),
                      _buildFilterChip('Transfer', FilterType.transfer),
                      _buildFilterChip('Top Up', FilterType.topup),
                      
                      // --- The "More" Filter Button ---
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () => _showExtraFilters(context),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isExtraFilterActive || _selectedDirection != TransactionDirection.all 
                                ? Colors.black87 
                                : Colors.white.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.transparent),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.filter_list, 
                                size: 16, 
                                color: (isExtraFilterActive || _selectedDirection != TransactionDirection.all) 
                                    ? Colors.white 
                                    : Colors.black87
                              ),
                              if (isExtraFilterActive) ...[
                                const SizedBox(width: 4),
                                Text(
                                  extraLabel,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12, 
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white
                                  ),
                                ),
                              ]
                            ],
                          ),
                        ),
                      ),
                    ],
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
                        return Center(child: Text('Error: ${snapshot.error}', style: TextStyle(color: Colors.red)));
                      }
                      
                      final allTransactions = snapshot.data ?? [];
                      final filteredTransactions = _applyFilter(allTransactions);

                      if (filteredTransactions.isEmpty) {
                         return Center(child: Text('No transactions found.', style: GoogleFonts.poppins(color: Colors.grey[700])));
                      }

                      final groupedTransactions = _groupTransactionsByDay(filteredTransactions);
                      final sortedDates = groupedTransactions.keys.toList()..sort((a, b) => b.compareTo(a)); 

                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        itemCount: sortedDates.length,
                        itemBuilder: (context, index) {
                          final dateKey = sortedDates[index];
                          final transactionsForDay = groupedTransactions[dateKey]!;
                          final String dateHeader = DateFormat('EEEE, d MMM yyyy').format(dateKey);

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 16.0, bottom: 8.0, left: 8.0),
                                child: Text(
                                  dateHeader,
                                  style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
                                ),
                              ),
                              ...transactionsForDay.map((tx) => TransactionTile(transaction: tx as Map<String, dynamic>,),).toList(),
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
