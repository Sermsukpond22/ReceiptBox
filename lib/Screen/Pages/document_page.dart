import 'package:flutter/material.dart'; 
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:run_android/services/receipt_service.dart';

class DocumentPage extends StatelessWidget {
  final ReceiptService _receiptService = ReceiptService();

  DocumentPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ใบเสร็จของฉัน')),
      body: StreamBuilder<QuerySnapshot>(
        stream: _receiptService.getUserReceipts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('เกิดข้อผิดพลาดในการโหลดข้อมูล'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('ยังไม่มีใบเสร็จ'));
          }

          final receipts = snapshot.data!.docs;

          return ListView.builder(
            itemCount: receipts.length,
            itemBuilder: (context, index) {
              final data = receipts[index].data() as Map<String, dynamic>;

              final String storeName = (data['storeName'] as String?)?.isNotEmpty == true
                  ? data['storeName'] as String
                  : 'ไม่มีชื่อร้าน';

              final double amount = (data['amount'] as num?)?.toDouble() ?? 0.0;

              final Timestamp? timestamp = data['transactionDate'] as Timestamp?;
              final DateTime transactionDate = timestamp?.toDate() ?? DateTime.now();

              final String? imageUrl = (data['imageUrl'] as String?)?.isNotEmpty == true ? data['imageUrl'] as String : null;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: imageUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            imageUrl,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const Icon(
                              Icons.broken_image,
                              size: 40,
                              color: Colors.grey,
                            ),
                          ),
                        )
                      : const Icon(Icons.receipt_long, size: 40, color: Colors.grey),
                  title: Text(storeName),
                  subtitle: Text(
                    '฿ ${amount.toStringAsFixed(2)} • ${DateFormat('dd MMM yyyy', 'th_TH').format(transactionDate)}',
                    style: const TextStyle(fontSize: 14),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    // TODO: ไปยังหน้ารายละเอียดใบเสร็จ (Detail Page)
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
