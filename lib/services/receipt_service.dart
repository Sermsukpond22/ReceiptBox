// receipt_service.dart
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
// import 'package:intl/intl.dart';



// Model สำหรับข้อมูลใบเสร็จ
class ReceiptData {
  final String? storeName;
  final String? description;
  final double amount;
  final DateTime transactionDate;
  final String? imageUrl;
  final File? imageFile;

  ReceiptData({
    this.storeName,
    this.description,
    required this.amount,
    required this.transactionDate,
    this.imageUrl,
    this.imageFile,
  });
}

// Service สำหรับจัดการใบเสร็จ
class ReceiptService {
  static final ReceiptService _instance = ReceiptService._internal();
  factory ReceiptService() => _instance;
  ReceiptService._internal();

  // Firebase instances
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ตรวจสอบการเข้าสู่ระบบ
  User? get currentUser => _auth.currentUser;
  
  bool get isUserLoggedIn => currentUser != null;

  // อัปโหลดรูปภาพไป Firebase Storage
  Future<String?> uploadReceiptImage(File imageFile) async {
    try {
      final user = currentUser;
      if (user == null) {
        throw Exception('กรุณาเข้าสู่ระบบก่อนใช้งาน');
      }

      final String fileName = 'receipt_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final Reference ref = _storage
          .ref()
          .child('receipts')
          .child(user.uid)
          .child(fileName);

      final UploadTask uploadTask = ref.putFile(imageFile);
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      throw Exception('เกิดข้อผิดพลาดในการอัปโหลดรูปภาพ: $e');
    }
  }

  // ลบรูปภาพจาก Firebase Storage
  Future<void> deleteReceiptImage(String imageUrl) async {
    try {
      final Reference ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      // อาจจะ log error แต่ไม่ throw เพราะไม่ critical
      print('ไม่สามารถลบรูปภาพได้: $e');
    }
  }

  // บันทึกใบเสร็จลง Firestore
  Future<String> saveReceipt(ReceiptData receiptData) async {
    try {
      final user = currentUser;
      if (user == null) {
        throw Exception('กรุณาเข้าสู่ระบบก่อนใช้งาน');
      }

      // อัปโหลดรูปภาพถ้ามี
      String? imageUrl;
      if (receiptData.imageFile != null) {
        imageUrl = await uploadReceiptImage(receiptData.imageFile!);
      }

      // เตรียมข้อมูลสำหรับบันทึก
      final Map<String, dynamic> data = {
        'userId': user.uid,
        'userEmail': user.email,
        'storeName': receiptData.storeName?.trim() ?? '',
        'description': receiptData.description?.trim() ?? '',
        'amount': receiptData.amount,
        'transactionDate': Timestamp.fromDate(receiptData.transactionDate),
        'createdAt': FieldValue.serverTimestamp(),
      };

      // เพิ่ม imageUrl ถ้ามี
      if (imageUrl != null) {
        data['imageUrl'] = imageUrl;
      }

      // บันทึกลง Firestore
      final DocumentReference docRef = await _firestore
          .collection('receipts')
          .add(data);

      return docRef.id;
    } catch (e) {
      throw Exception('บันทึกใบเสร็จไม่สำเร็จ: $e');
    }
  }

  // อัปเดตใบเสร็จ
  Future<void> updateReceipt(String receiptId, ReceiptData receiptData) async {
    try {
      final user = currentUser;
      if (user == null) {
        throw Exception('กรุณาเข้าสู่ระบบก่อนใช้งาน');
      }

      // อัปโหลดรูปภาพใหม่ถ้ามี
      String? imageUrl = receiptData.imageUrl;
      if (receiptData.imageFile != null) {
        imageUrl = await uploadReceiptImage(receiptData.imageFile!);
      }

      // เตรียมข้อมูลสำหรับอัปเดต
      final Map<String, dynamic> data = {
        'storeName': receiptData.storeName?.trim() ?? '',
        'description': receiptData.description?.trim() ?? '',
        'amount': receiptData.amount,
        'transactionDate': Timestamp.fromDate(receiptData.transactionDate),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // เพิ่ม imageUrl ถ้ามี
      if (imageUrl != null) {
        data['imageUrl'] = imageUrl;
      }

      // อัปเดตใน Firestore
      await _firestore
          .collection('receipts')
          .doc(receiptId)
          .update(data);
    } catch (e) {
      throw Exception('อัปเดตใบเสร็จไม่สำเร็จ: $e');
    }
  }

  // ลบใบเสร็จ
  Future<void> deleteReceipt(String receiptId, {String? imageUrl}) async {
    try {
      final user = currentUser;
      if (user == null) {
        throw Exception('กรุณาเข้าสู่ระบบก่อนใช้งาน');
      }

      // ลบรูปภาพก่อนถ้ามี
      if (imageUrl != null && imageUrl.isNotEmpty) {
        await deleteReceiptImage(imageUrl);
      }

      // ลบเอกสารจาก Firestore
      await _firestore
          .collection('receipts')
          .doc(receiptId)
          .delete();
    } catch (e) {
      throw Exception('ลบใบเสร็จไม่สำเร็จ: $e');
    }
  }

  // ดึงใบเสร็จของผู้ใช้
  Stream<QuerySnapshot> getUserReceipts({
    int? limit,
    DocumentSnapshot? startAfter,
  }) {
    final user = currentUser;
    if (user == null) {
      throw Exception('กรุณาเข้าสู่ระบบก่อนใช้งาน');
    }

    Query query = _firestore
        .collection('receipts')
        .where('userId', isEqualTo: user.uid)
        .orderBy('transactionDate', descending: true);

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots();
  }

  // ดึงใบเสร็จตาม ID
  Future<DocumentSnapshot> getReceiptById(String receiptId) async {
    try {
      return await _firestore
          .collection('receipts')
          .doc(receiptId)
          .get();
    } catch (e) {
      throw Exception('ดึงข้อมูลใบเสร็จไม่สำเร็จ: $e');
    }
  }

  // ดึงใบเสร็จตามช่วงวันที่
  Stream<QuerySnapshot> getReceiptsByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) {
    final user = currentUser;
    if (user == null) {
      throw Exception('กรุณาเข้าสู่ระบบก่อนใช้งาน');
    }

    return _firestore
        .collection('receipts')
        .where('userId', isEqualTo: user.uid)
        .where('transactionDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('transactionDate', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .orderBy('transactionDate', descending: true)
        .snapshots();
  }

  // คำนวณยอดรวมในช่วงวันที่
  Future<double> calculateTotalAmount({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final user = currentUser;
      if (user == null) {
        throw Exception('กรุณาเข้าสู่ระบบก่อนใช้งาน');
      }

      final QuerySnapshot snapshot = await _firestore
          .collection('receipts')
          .where('userId', isEqualTo: user.uid)
          .where('transactionDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('transactionDate', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      double total = 0.0;
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        total += (data['amount'] as num?)?.toDouble() ?? 0.0;
      }

      return total;
    } catch (e) {
      throw Exception('คำนวณยอดรวมไม่สำเร็จ: $e');
    }
  }

  // ตรวจสอบความถูกต้องของข้อมูล
  static String? validateReceiptData(ReceiptData receiptData) {
    if (receiptData.amount <= 0) {
      return 'กรุณากรอกจำนวนเงินที่ถูกต้อง';
    }

    if (receiptData.transactionDate.isAfter(DateTime.now())) {
      return 'วันที่ไม่สามารถเป็นอนาคตได้';
    }

    return null; // ข้อมูลถูกต้อง
  }
}