import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BalanceCardWidget extends StatelessWidget {
  final double balance;
  final double totalExpense;

  const BalanceCardWidget({
    super.key,
    required this.balance,
    required this.totalExpense,
  });

  String _formatCurrency(double amount) {
    final format = NumberFormat.currency(locale: 'th_TH', symbol: '฿');
    return format.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        padding: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            colors: [Color(0xFF007BFF), Color(0xFF0056B3)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ยอดการใช้จ่ายทั้งหมด',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              _formatCurrency(balance),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            // === ส่วนที่แก้ไข: แสดงเฉพาะรายจ่าย ===
            
          ],
        ),
      ),
    );
  }

}