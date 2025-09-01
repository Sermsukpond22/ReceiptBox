import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:run_android/Screen/Pages/Category_manage/Widgets/Receipt/receipt_detail_page.dart';
import 'package:run_android/Screen/Pages/Category_manage/Widgets/Receipt/all_receipt_page.dart'; // ✅ Import AllReceiptsPage

class RecentTransactionsList extends StatelessWidget {
  final List<QueryDocumentSnapshot> transactions;
  final List<Map<String, dynamic>> categories;

  const RecentTransactionsList({
    super.key,
    required this.transactions,
    required this.categories,
  });

  String _formatCurrency(double amount) {
    final format = NumberFormat.currency(locale: 'th_TH', symbol: '฿');
    return format.format(amount);
  }

  String _formatDate(Timestamp timestamp) {
    final format = DateFormat('d MMM yy', 'th_TH');
    return format.format(timestamp.toDate());
  }

  // This function should ideally be in a utility or CategoryModel
  // to properly map iconCodePoint to IconData.
  // For simplicity, I'm keeping it here as per the original code structure.
  IconData _getIconData(String? iconCodePointString) {
    if (iconCodePointString == null) return Icons.receipt; // Default icon

    try {
      final int codePoint = int.parse(iconCodePointString);
      return IconData(codePoint, fontFamily: 'MaterialIcons');
    } catch (e) {
      // Fallback if parsing fails
      return Icons.receipt;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('รายการล่าสุด', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              TextButton(
                onPressed: () {
                  // ✅ เชื่อมปุ่ม "ดูทั้งหมด" ไปยัง AllReceiptsPage
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AllReceiptsPage(),
                    ),
                  );
                },
                child: const Text('ดูทั้งหมด'),
              ),
            ],
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: transactions.length > 5 ? 5 : transactions.length, // Show up to 5 recent transactions
            itemBuilder: (context, index) {
              final doc = transactions[index];
              final data = doc.data() as Map<String, dynamic>;

              data['docId'] = doc.id; // Add docId to the map for detail page

              final storeName = data['storeName'] ?? 'ไม่มีชื่อร้าน';
              final amount = (data['amount'] as num).toDouble();
              final date = data['transactionDate'] as Timestamp;
              final categoryName = data['category'] as String? ?? 'default';

              // Find the category to get its iconCodePoint
              final categoryMatch = categories.firstWhere(
                (cat) => cat['name'] == categoryName,
                orElse: () => {'iconCodePoint': Icons.receipt.codePoint.toString()}, // Fallback for iconCodePoint
              );
              
              // Use the iconCodePoint from the matched category
              final IconData icon = _getIconData(categoryMatch['iconCodePoint']);

              return Card(
                elevation: 0,
                color: Colors.white,
                margin: const EdgeInsets.symmetric(vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                clipBehavior: Clip.antiAlias,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: amount < 0 ? Colors.red[50] : Colors.green[50],
                    child: Icon(icon, color: amount < 0 ? Colors.red : Colors.green),
                  ),
                  title: Text(storeName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(_formatDate(date)),
                  trailing: Text(
                    _formatCurrency(amount),
                    style: TextStyle(
                      color: amount < 0 ? Colors.red : Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ReceiptDetailPage(
                          receiptData: data, // Pass all receipt data
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
