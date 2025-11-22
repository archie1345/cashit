import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
enum TransactionType { topUp, transfer }

class TransactionstatusPage extends StatelessWidget {
  final int amount;
  final DateTime transactionDate;
  final bool isSuccess;
  final TransactionType type;
  final String? serviceName;

  const TransactionstatusPage({
    super.key,
    required this.amount,
    required this.transactionDate,
    required this.type,
    this.isSuccess = true,
    this.serviceName
  });

  String _formatCurrency(int amount) {
    return NumberFormat.currency(
      locale: 'en_US',
      symbol: '\$ ',
      decimalDigits: 2,
    ).format(amount/100);
  }

  String _formatDate(DateTime date) {
    return DateFormat('d MMM yyyy HH:mm:ss').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = isSuccess ? Colors.green[400] : Colors.red[400];
    final statusIcon = isSuccess ? Icons.check_circle_outline : Icons.cancel_outlined;
    String statusTitle;
    String statusMessage;

    if (serviceName != null) {
      statusTitle = isSuccess ? '$serviceName Paid!' : '$serviceName Failed';
      statusMessage = isSuccess ? '$serviceName payment successful' : 'Could not pay bill.';
    } else if (type == TransactionType.topUp) {
      statusTitle = isSuccess ? 'Top up Succeeded!' : 'Top up Failed';
      statusMessage = isSuccess ? 'Debit Card' : 'Payment was canceled or failed.';
    } else {
      statusTitle = isSuccess ? 'Transfer Sent!' : 'Transfer Failed';
      statusMessage = isSuccess ? 'Funds sent successfully' : 'Transfer could not be completed.';
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pushNamedAndRemoveUntil(
            context,
            '/home',
            (route) => false,
          ),
        ),
        title: Text('Transaction Status', style: GoogleFonts.poppins(color: Colors.black)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: PopScope(
        canPop: false,
        onPopInvoked: (didPop) {
           if (didPop) return;
           Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
        },
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(30.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isSuccess ? Colors.green[50] : Colors.red[50],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    statusIcon,
                    color: statusColor,
                    size: 80,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  statusTitle,
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                
                Text(
                  _formatCurrency(amount),
                  style: GoogleFonts.poppins(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    decoration: isSuccess ? null : TextDecoration.lineThrough, // Strike through on fail
                    decorationColor: Colors.red,
                  ),
                ),
                
                const SizedBox(height: 40),
                _buildDetailRow(
                  'Transaction Date',
                  _formatDate(transactionDate),
                ),
                _buildDetailRow(
                  type == TransactionType.topUp 
                    ? (isSuccess ? 'Payment Method' : 'Status')
                    : 'Details', 
                  statusMessage,
                ),

                const Spacer(),
                
                if (!isSuccess)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () {
                          if (type == TransactionType.topUp) {
                            Navigator.pushReplacementNamed(context, '/add_balance');
                          } else {
                            Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
                          }
                        },
                        child: Text(
                          'Try Again',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Colors.black),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => Navigator.pushNamedAndRemoveUntil(
                      context, 
                      '/home', 
                      (route) => false
                    ),
                    child: Text(
                      'Back to Home',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}