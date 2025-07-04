import 'package:cloud_firestore/cloud_firestore.dart';

class Receipt {
  final String id;
  final String userId;
  final String storeName;
  final String? description;
  final double amount;
  final DateTime transactionDate;
  final String? imageUrl;

  const Receipt({
    required this.id,
    required this.userId,
    required this.storeName,
    this.description,
    required this.amount,
    required this.transactionDate,
    this.imageUrl,
  });

  factory Receipt.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;

    if (data == null) {
      throw StateError('Missing data for receiptId: ${doc.id}');
    }

    return Receipt(
      id: doc.id,
      userId: data['userId'] ?? '',
      storeName: (data['storeName'] as String?)?.isNotEmpty == true
          ? data['storeName']
          : 'ไม่มีชื่อร้าน',
      description: data['description'],
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      transactionDate: (data['transactionDate'] as Timestamp).toDate(),
      imageUrl: data['imageUrl'],
    );
  }
}