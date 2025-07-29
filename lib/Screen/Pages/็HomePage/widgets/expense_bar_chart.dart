// lib/Screen/Pages/HomePage/widgets/expense_bar_chart.dart

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

/// Data model for each bar in the chart
class CategoryExpense {
  final String categoryName;
  final double amount;
  final Color color; // Use Flutter's Color directly

  CategoryExpense(this.categoryName, this.amount, this.color);
}

class ExpenseBarChart extends StatelessWidget {
  final List<CategoryExpense> data;

  const ExpenseBarChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    // Determine the maximum amount for scaling the chart
    double maxAmount = data.isNotEmpty ? data.map((e) => e.amount).reduce(
        (a, b) => a > b ? a : b) : 1.0; // Ensure maxAmount is at least 1.0

    // Prepare BarChartGroupData for FL_Chart
    List<BarChartGroupData> barGroups = [];
    for (int i = 0; i < data.length; i++) {
      final item = data[i];
      barGroups.add(
        BarChartGroupData(
          x: i, // X-axis value (index)
          barRods: [
            BarChartRodData(
              toY: item.amount, // Y-axis value (amount)
              color: item.color,
              width: 16, // Width of the bar
              borderRadius: BorderRadius.circular(4),
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: maxAmount, // Max value for background rod
                color: Colors.grey.withOpacity(0.2),
              ),
            ),
          ],
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.all(16.0),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'รายจ่ายแยกตามหมวดหมู่',
              style: GoogleFonts.prompt(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 250, // Fixed height for the chart
              child: BarChart(
                BarChartData(
                  barGroups: barGroups,
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxAmount * 1.1, // Add some padding to the top of the chart
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          // Display category names on the bottom axis
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: RotatedBox(
                              quarterTurns: 0, // No rotation for horizontal bars, but for vertical, it would be 1
                              child: Text(
                                data[value.toInt()].categoryName,
                                style: GoogleFonts.prompt(fontSize: 12, color: Colors.grey[600]),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          );
                        },
                        reservedSize: 40, // Space for labels
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          // Display amount labels on the left axis
                          if (value == meta.max) return const Text(''); // Hide max value label
                          return Text(
                            NumberFormat("#,##0").format(value),
                            style: GoogleFonts.prompt(fontSize: 12, color: Colors.grey[600]),
                          );
                        },
                        reservedSize: 40, // Space for labels
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false, // No vertical grid lines
                    getDrawingHorizontalLine: (value) => FlLine( // ✅ Corrected method name
                      color: Colors.grey.withAlpha((0.3 * 255).toInt()), // ✅ Corrected color alpha
                      strokeWidth: 0.5,
                    ),
                  ),
                  borderData: FlBorderData(
                    show: false, // Hide border
                  ),
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      //backgroundColor: Colors.blueGrey.shade700, // ✅ Corrected color
                      tooltipRoundedRadius: 8,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final category = data[group.x.toInt()];
                        return BarTooltipItem(
                          '${category.categoryName}\n',
                          GoogleFonts.prompt(color: Colors.white, fontWeight: FontWeight.bold),
                          children: [
                            TextSpan(
                              text: _formatCurrency(rod.toY),
                              style: GoogleFonts.prompt(color: Colors.white),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatCurrency(double amount) {
    final format = NumberFormat.currency(locale: 'th_TH', symbol: '฿');
    return format.format(amount);
  }
}
