import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ReceiptDetailPage extends StatelessWidget {
  final Map<String, dynamic> receiptData;

  const ReceiptDetailPage({Key? key, required this.receiptData}) : super(key: key);

  // --- ฟังก์ชันสำหรับลบข้อมูล ---
  Future<void> _deleteReceipt(BuildContext context, String docId) async {
    try {
      // แสดง Loading Dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(child: CircularProgressIndicator());
        },
      );

      // ลบรูปภาพจาก Storage (ถ้ามี)
      // ตรวจสอบให้แน่ใจว่าเป็น String และไม่ว่างเปล่า
      if (receiptData['imageUrl'] is String && (receiptData['imageUrl'] as String).isNotEmpty) {
        final ref = FirebaseStorage.instance.refFromURL(receiptData['imageUrl']);
        await ref.delete();
      }

      // ลบข้อมูลจาก Firestore
      await FirebaseFirestore.instance.collection('receipts').doc(docId).delete();

      if (context.mounted) {
        Navigator.pop(context); // ปิด Loading Dialog
        Navigator.pop(context); // กลับไปหน้า List (เพราะลบสำเร็จแล้ว)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ลบใบเสร็จเรียบร้อยแล้ว', style: GoogleFonts.prompt()),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // ปิด Loading Dialog แม้จะมีข้อผิดพลาด
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e', style: GoogleFonts.prompt()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // --- Build Method หลัก ---
  @override
  Widget build(BuildContext context) {
    // ดึง docId ออกมาโดยตรงจาก receiptData
    final docId = receiptData['docId'] as String?;
    final transactionDate = (receiptData['transactionDate'] as Timestamp?)?.toDate();
    final formattedDate = transactionDate != null
        ? DateFormat('d MMMM yyyy, เวลา HH:mm', 'th').format(transactionDate) // ปรับปรุงรูปแบบวันที่
        : 'ไม่ระบุวันที่';
    final amount = (receiptData['amount'] as num?)?.toDouble() ?? 0.0;
    final imageUrl = receiptData['imageUrl'] as String?;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        title: Text('รายละเอียดใบเสร็จ', style: GoogleFonts.prompt(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_note_outlined),
            onPressed: () {
              // TODO: เชื่อมหน้าจอแก้ไขใบเสร็จ
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('ยังไม่ได้เชื่อมต่อหน้าจอแก้ไข', style: GoogleFonts.prompt())),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () async {
              if (docId == null) {
                // แสดง Snackbar หาก docId เป็น null ไม่สามารถลบได้
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('ไม่สามารถลบได้: ไม่พบรหัสเอกสาร', style: GoogleFonts.prompt()),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }
              final confirm = await _showDeleteConfirmationDialog(context);
              if (confirm == true) {
                await _deleteReceipt(context, docId); // ส่ง docId ตรงๆ
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ✨ ส่วนแสดงรูปภาพ (ถ้ามี)
            if (imageUrl != null && imageUrl.isNotEmpty) ...[
              // *** จุดที่อาจเกี่ยวข้องกับปัญหา Hero Tag ของคุณ ***
              // ถ้าคุณใช้ Hero widget ในหน้า List เพื่อแสดงรูปภาพนี้
              // คุณควรจะใช้ Hero widget ที่นี่ด้วย โดยมี tag ที่ไม่ซ้ำกับ Hero widget ตัวอื่นๆ ในหน้าเดียวกัน
              // และเป็น tag เดียวกันกับ Hero widget ที่ใช้ในหน้า List ของใบเสร็จนี้
              // ตัวอย่าง: Hero(tag: 'receipt-image-${docId}', child: Image.network(...))
              _buildHeaderImage(imageUrl),
              const SizedBox(height: 20),
            ],

            // ✨ ส่วนแสดงยอดเงินให้เด่นชัด
            _buildAmountCard(amount),
            const SizedBox(height: 20),

            // ✨ Card ที่รวบรวมรายละเอียดทั้งหมด
            _buildDetailsCard(formattedDate),
          ],
        ),
      ),
    );
  }

  // --- Helper Widgets สำหรับสร้าง UI ส่วนต่างๆ ---

  /// Widget สำหรับแสดงรูปภาพ Header
  Widget _buildHeaderImage(String imageUrl) {
    return Card(
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      clipBehavior: Clip.antiAlias,
      child: Image.network(
        imageUrl,
        height: 250,
        width: double.infinity,
        fit: BoxFit.cover,
        // ✨ แสดง Loading ขณะโหลดรูป
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            height: 250,
            color: Colors.grey[200],
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                    : null,
              ),
            ),
          );
        },
        // ✨ แสดง Icon Error หากโหลดรูปไม่สำเร็จ
        errorBuilder: (context, error, stackTrace) {
          return Container(
            height: 250,
            color: Colors.grey[200],
            child: Icon(Icons.image_not_supported_outlined, color: Colors.grey[400], size: 60),
          );
        },
      ),
    );
  }

  /// Widget สำหรับแสดงยอดเงิน
  Widget _buildAmountCard(double amount) {
    return Card(
      elevation: 2,
      color: Colors.green[50],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Column(
          children: [
            Text(
              'ยอดชำระ',
              style: GoogleFonts.prompt(fontSize: 16, color: Colors.green[900]),
            ),
            const SizedBox(height: 8),
            Text(
              '${NumberFormat("#,##0.00").format(amount)} ฿',
              style: GoogleFonts.prompt(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.green[800],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Widget สำหรับแสดงรายละเอียดอื่นๆ ใน Card
  Widget _buildDetailsCard(String formattedDate) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildInfoRow(
              icon: Icons.store_mall_directory_outlined,
              title: 'ร้านค้า',
              value: receiptData['storeName'] ?? 'ไม่ระบุ',
            ),
            const Divider(height: 24),
            _buildInfoRow(
              icon: Icons.description_outlined,
              title: 'รายละเอียด',
              value: receiptData['description'] ?? '-',
            ),
            const Divider(height: 24),
            _buildInfoRow(
              icon: Icons.calendar_today_outlined,
              title: 'วันที่ทำรายการ',
              value: formattedDate,
            ),
            const Divider(height: 24),
            _buildInfoRow(
              icon: Icons.person_outline,
              title: 'บันทึกโดย',
              value: receiptData['userEmail'] ?? '-',
            ),
          ],
        ),
      ),
    );
  }

  /// Widget สำหรับสร้างแถวข้อมูลแต่ละรายการ (Icon + Title + Value)
  Widget _buildInfoRow({required IconData icon, required String title, required String value}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.grey[600], size: 22),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.prompt(fontSize: 14, color: Colors.grey[700]),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: GoogleFonts.prompt(fontSize: 16, fontWeight: FontWeight.w500, height: 1.4),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 🎨 Widget สำหรับแสดง Dialog ยืนยันการลบที่ออกแบบใหม่
  Future<bool?> _showDeleteConfirmationDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text('ยืนยันการลบ', style: GoogleFonts.prompt(fontWeight: FontWeight.bold)),
        content: Text('คุณแน่ใจหรือไม่ว่าต้องการลบใบเสร็จนี้? การกระทำนี้ไม่สามารถย้อนกลับได้', style: GoogleFonts.prompt()),
        actions: [
          TextButton(
            child: Text('ยกเลิก', style: GoogleFonts.prompt()),
            onPressed: () => Navigator.pop(context, false),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text('ยืนยันการลบ', style: GoogleFonts.prompt()),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );
  }
}