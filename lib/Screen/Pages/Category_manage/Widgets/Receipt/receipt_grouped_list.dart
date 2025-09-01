import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'receipt_card.dart';

// เปลี่ยนจาก ListView แบบกลุ่ม เป็น ListView แบบธรรมดา
class ReceiptGroupedListView extends StatelessWidget {
  final List<QueryDocumentSnapshot> docs;

  const ReceiptGroupedListView({Key? key, required this.docs}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // ไม่มีการจัดกลุ่มอีกต่อไป ใช้ ListView.builder ได้เลย
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: docs.length, // จำนวน item คือจำนวนเอกสารทั้งหมด
      itemBuilder: (context, index) {
        final doc = docs[index];
        final data = doc.data() as Map<String, dynamic>;
        data['docId'] = doc.id;
        
        // ส่ง data ไปให้ ReceiptCard แสดงผลทีละใบ
        return ReceiptCard(data: data);
      },
    );
  }
}