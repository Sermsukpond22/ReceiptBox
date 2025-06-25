import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:run_android/services/receipt_service.dart';

class DocumentPage extends StatelessWidget {
  final ReceiptService _receiptService = ReceiptService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('ใบเสร็จของฉัน')),
      body: StreamBuilder<QuerySnapshot>(
        stream: _receiptService.getUserReceipts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('เกิดข้อผิดพลาดในการโหลดข้อมูล'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('ยังไม่มีใบเสร็จ'));
          }

          final receipts = snapshot.data!.docs;

          return ListView.builder(
            itemCount: receipts.length,
            itemBuilder: (context, index) {
              final data = receipts[index].data() as Map<String, dynamic>;

              final String storeName = (data['storeName'] as String?) ?? 'ไม่มีชื่อร้าน';
              final double amount = data['amount'] != null ? (data['amount'] as num).toDouble() : 0.0;
              final DateTime transactionDate = data['transactionDate'] != null
                  ? (data['transactionDate'] as Timestamp).toDate()
                  : DateTime.now();
              final String? imageUrl = data['imageUrl'] as String?;

              return Card(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: imageUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(imageUrl, width: 50, height: 50, fit: BoxFit.cover),
                        )
                      : Icon(Icons.receipt_long, size: 40, color: Colors.grey[600]),
                  title: Text(storeName),
                  subtitle: Text('฿ ${amount.toStringAsFixed(2)} • ${DateFormat('dd MMM yyyy').format(transactionDate)}'),
                  trailing: Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    // TODO: ไปยังหน้ารายละเอียดใบเสร็จ
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
