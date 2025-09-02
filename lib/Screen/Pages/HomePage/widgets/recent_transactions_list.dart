import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:run_android/Screen/Pages/Category_manage/Widgets/Receipt/all_receipt_page.dart';
import 'package:run_android/Screen/Pages/Category_manage/Widgets/Receipt/receipt_detail_page.dart';


// ✅ 1. Import the Category model
import 'package:run_android/models/category_model.dart';

class RecentTransactionsList extends StatelessWidget {
  final List<QueryDocumentSnapshot> transactions;
  // ✅ 2. Change the type to List<Category>
  final List<Category> categories;

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
    // Switched to a more common date format
    final format = DateFormat('d MMM yyyy', 'th_TH');
    return format.format(timestamp.toDate());
  }

  // ❌ 3. Remove the old _getIconData function entirely

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('รายการล่าสุด', style: GoogleFonts.prompt(fontSize: 18, fontWeight: FontWeight.bold)),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AllReceiptsPage(),
                    ),
                  );
                },
                child: Text('ดูทั้งหมด', style: GoogleFonts.prompt()),
              ),
            ],
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            // Show up to 5 recent transactions
            itemCount: transactions.length > 5 ? 5 : transactions.length,
            itemBuilder: (context, index) {
              final doc = transactions[index];
              final data = doc.data() as Map<String, dynamic>;
              data['docId'] = doc.id;

              final storeName = data['storeName'] ?? 'ไม่มีชื่อร้าน';
              final amount = (data['amount'] as num).toDouble();
              final date = data['transactionDate'] as Timestamp;
              // Ensure you save 'categoryName' in your transaction documents
              final categoryName = data['categoryName'] as String? ?? 'ไม่ระบุหมวดหมู่';

              // ✅ 4. Find the matching Category object
              Category? categoryMatch;
              try {
                 categoryMatch = categories.firstWhere(
                   (cat) => cat.name == categoryName,
                 );
              } catch (e) {
                // If no category is found, categoryMatch will remain null
                categoryMatch = null;
              }

              // Use the icon from the matched category, or a default one
              final IconData icon = categoryMatch?.icon ?? Icons.category;

              return Card(
                elevation: 0,
                color: Colors.white,
                margin: const EdgeInsets.symmetric(vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                clipBehavior: Clip.antiAlias,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: amount < 0 ? Colors.red[50] : Colors.green[50],
                    child: Icon(icon, color: amount < 0 ? Colors.red.shade400 : Colors.green.shade600),
                  ),
                  title: Text(storeName, style: GoogleFonts.prompt(fontWeight: FontWeight.bold)),
                  subtitle: Text(_formatDate(date), style: GoogleFonts.prompt()),
                  trailing: Text(
                    _formatCurrency(amount),
                    style: GoogleFonts.prompt(
                      color: amount < 0 ? Colors.red.shade800 : Colors.green.shade800,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ReceiptDetailPage(
                          receiptData: data,
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