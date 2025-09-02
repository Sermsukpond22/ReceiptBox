// lib/Screen/Pages/HomePage/widgets/balance_card_widget.dart

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:run_android/Screen/Pages/HomePage/widgets/expense_bar_chart.dart';



class BalanceCardWidget extends StatefulWidget {
  final double balance;
  final double totalExpense;
  final List<CategoryExpense> expenseData;

  const BalanceCardWidget({
    super.key,
    required this.balance,
    required this.totalExpense,
    required this.expenseData,
  });

  @override
  State<BalanceCardWidget> createState() => _BalanceCardWidgetState();
}

class _BalanceCardWidgetState extends State<BalanceCardWidget> {
  int? touchedIndex;

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
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ยอดใช้จ่าย',
                    style: GoogleFonts.prompt(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatCurrency(widget.totalExpense),
                    style: GoogleFonts.prompt(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'คงเหลือ',
                    style: GoogleFonts.prompt(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatCurrency(widget.balance),
                     style: GoogleFonts.prompt(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 3,
              child: AspectRatio(
                aspectRatio: 1,
                child: PieChart(
                  PieChartData(
                    pieTouchData: PieTouchData(
                      touchCallback: (FlTouchEvent event, pieTouchResponse) {
                        setState(() {
                          if (!event.isInterestedForInteractions ||
                              pieTouchResponse == null ||
                              pieTouchResponse.touchedSection == null) {
                            touchedIndex = -1;
                            return;
                          }
                          touchedIndex = pieTouchResponse
                              .touchedSection!.touchedSectionIndex;
                        });
                      },
                    ),
                    borderData: FlBorderData(show: false),
                    sectionsSpace: 2,
                    centerSpaceRadius: 25,
                    sections: _showingSections(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _showingSections() {
    if (widget.expenseData.isEmpty) {
      return [
        PieChartSectionData(
          color: Colors.blueGrey[700]?.withOpacity(0.5),
          value: 1,
          title: '0%',
          radius: 30.0,
          titleStyle: GoogleFonts.prompt(
            fontSize: 12.0,
            fontWeight: FontWeight.bold,
            color: Colors.white
          ),
        ),
      ];
    }

    return List.generate(widget.expenseData.length, (i) {
      final isTouched = i == touchedIndex;
      final fontSize = isTouched ? 14.0 : 10.0;
      final radius = isTouched ? 45.0 : 35.0;
      final expense = widget.expenseData[i];
      final percentage = widget.totalExpense > 0 ? (expense.amount / widget.totalExpense) * 100 : 0.0;

      return PieChartSectionData(
        color: expense.color,
        value: expense.amount,
        title: '${percentage.toStringAsFixed(0)}%',
        radius: radius,
        titleStyle: GoogleFonts.prompt(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: [
            const Shadow(color: Colors.black26, blurRadius: 2)
          ]
        ),
      );
    });
  }
}