import 'package:photo_view/photo_view.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:run_android/services/shere_service.dart';
import 'edit_receipt_page.dart';


class ReceiptDetailPage extends StatefulWidget {
  final Map<String, dynamic> receiptData;

  const ReceiptDetailPage({Key? key, required this.receiptData})
      : super(key: key);

  @override
  State<ReceiptDetailPage> createState() => _ReceiptDetailPageState();
}

class _ReceiptDetailPageState extends State<ReceiptDetailPage> {
  final GlobalKey _qrKey = GlobalKey();
  bool _isLoading = false;

  /// ลบใบเสร็จพร้อมจัดการ Error และ Loading
  Future<void> _deleteReceipt(BuildContext context, String docId) async {
    setState(() => _isLoading = true);

    try {
      // ลบรูปภาพจาก Storage (ถ้ามี)
      await _deleteImageFromStorage();

      // ลบข้อมูลจาก Firestore
      await FirebaseFirestore.instance
          .collection('receipts')
          .doc(docId)
          .delete();

      if (mounted) {
        _showSuccessAndNavigateBack();
      }
    } catch (e) {
      if (mounted) {
        _showErrorMessage('เกิดข้อผิดพลาด: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// ลบรูปภาพจาก Firebase Storage
  Future<void> _deleteImageFromStorage() async {
    final imageUrl = widget.receiptData['imageUrl'];
    if (imageUrl is String && imageUrl.isNotEmpty) {
      try {
        final ref = FirebaseStorage.instance.refFromURL(imageUrl);
        await ref.delete();
      } catch (e) {
        print('ไม่สามารถลบรูปภาพได้: $e');
        // ไม่ throw error เพราะอาจเป็นเพียงรูปที่ถูกลบไปแล้ว
      }
    }
  }

  /// แสดงข้อความสำเร็จและกลับไปหน้าก่อน
  void _showSuccessAndNavigateBack() {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('ลบใบเสร็จเรียบร้อยแล้ว', style: GoogleFonts.prompt()),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// แสดงข้อความ Error
  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.prompt()),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// แสดงหน้าต่างดูรูปภาพแบบเต็มจอ
  void _showPhotoViewer(BuildContext context, String imageUrl, String heroTag) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close',
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, anim1, anim2) {
        return Scaffold(
          backgroundColor: Colors.black.withOpacity(0.9),
          body: Stack(
            children: [
              Hero(
                tag: heroTag,
                child: PhotoView(
                  imageProvider: NetworkImage(imageUrl),
                  minScale: PhotoViewComputedScale.contained,
                  maxScale: PhotoViewComputedScale.covered * 2.0,
                  backgroundDecoration: const BoxDecoration(
                    color: Colors.transparent,
                  ),
                  loadingBuilder: (context, event) => const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                  errorBuilder: (context, error, stackTrace) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.white,
                          size: 64,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'ไม่สามารถโหลดรูปภาพได้',
                          style: GoogleFonts.prompt(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // ปุ่มปิด
              Positioned(
                top: MediaQuery.of(context).padding.top + 10,
                right: 20.0,
                child: Material(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 24),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// แสดง Dialog ยืนยันการลบ
  Future<bool?> _showDeleteConfirmationDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, 
                color: Colors.orange[700], size: 28),
            const SizedBox(width: 12),
            Text('ยืนยันการลบ',
                style: GoogleFonts.prompt(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'คุณแน่ใจหรือไม่ว่าต้องการลบใบเสร็จนี้?\n\nการกระทำนี้จะลบ:\n• ข้อมูลใบเสร็จทั้งหมด\n• รูปภาพที่เกี่ยวข้อง\n\nและไม่สามารถกู้คืนได้',
          style: GoogleFonts.prompt(height: 1.5),
        ),
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

  @override
  Widget build(BuildContext context) {
    final docId = widget.receiptData['docId'] as String?;
    final transactionDate =
        (widget.receiptData['transactionDate'] as Timestamp?)?.toDate();
    final formattedDate = transactionDate != null
        ? DateFormat('d MMMM yyyy, เวลา HH:mm', 'th').format(transactionDate)
        : 'ไม่ระบุวันที่';
    final amount = (widget.receiptData['amount'] as num?)?.toDouble() ?? 0.0;
    final imageUrl = widget.receiptData['imageUrl'] as String?;

    final heroTag = 'receipt-image-${docId ?? UniqueKey().toString()}';

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        title: Text('รายละเอียดใบเสร็จ',
            style: GoogleFonts.prompt(fontWeight: FontWeight.bold)),
        actions: [
          // ปุ่มแชร์
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _isLoading ? null : () {
              ShareService.showShareOptions(context, widget.receiptData, _qrKey);
            },
            tooltip: 'แชร์ใบเสร็จ',
          ),
          // ปุ่มแก้ไข
          IconButton(
            icon: const Icon(Icons.edit_note_outlined),
            onPressed: _isLoading ? null : () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      EditReceiptPage(receiptData: widget.receiptData),
                ),
              );
            },
            tooltip: 'แก้ไขใบเสร็จ',
          ),
          // ปุ่มลบ
          IconButton(
            icon: _isLoading 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: _isLoading ? null : () async {
              if (docId == null) {
                _showErrorMessage('ไม่สามารถลบได้: ไม่พบรหัสเอกสาร');
                return;
              }
              final confirm = await _showDeleteConfirmationDialog(context);
              if (confirm == true) {
                await _deleteReceipt(context, docId);
              }
            },
            tooltip: 'ลบใบเสร็จ',
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // รูปภาพใบเสร็จ (ถ้ามี)
                if (imageUrl != null && imageUrl.isNotEmpty) ...[
                  GestureDetector(
                    onTap: () => _showPhotoViewer(context, imageUrl, heroTag),
                    child: Hero(
                      tag: heroTag,
                      child: _buildHeaderImage(imageUrl),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                
                // การ์ดแสดงยอดเงิน
                _buildAmountCard(amount),
                const SizedBox(height: 20),
                
                // การ์ดแสดงรายละเอียด
                _buildDetailsCard(formattedDate),
                const SizedBox(height: 20),
                
                // ปุ่มแชร์ด่วน
                _buildQuickShareButtons(),
                const SizedBox(height: 20),
              ],
            ),
          ),
          
          // Loading Overlay
          if (_isLoading)
            Container(
              color: Colors.black26,
              child: const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('กำลังดำเนินการ...'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// สร้างปุ่มแชร์ด่วน
  Widget _buildQuickShareButtons() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.share, color: Colors.blue[700]),
                const SizedBox(width: 8),
                Text(
                  'แชร์ใบเสร็จ',
                  style: GoogleFonts.prompt(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildQuickShareButton(
                    icon: Icons.picture_as_pdf,
                    label: 'PDF',
                    color: Colors.red,
                    onPressed: () async {
                      await ShareService.generateAndSharePDF(context, widget.receiptData);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickShareButton(
                    icon: Icons.qr_code,
                    label: 'QR Code',
                    color: Colors.blue,
                    onPressed: () async {
                      await ShareService.generateAndShareQR(context, widget.receiptData, _qrKey);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickShareButton(
                    icon: Icons.text_fields,
                    label: 'ข้อความ',
                    color: Colors.green,
                    onPressed: () async {
                      await ShareService.shareAsText(widget.receiptData);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// สร้างปุ่มแชร์แต่ละประเภท
  Widget _buildQuickShareButton({
    required IconData icon,
    required String label,
    required MaterialColor color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: _isLoading ? null : onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label, style: GoogleFonts.prompt(fontSize: 12)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color[50],
        foregroundColor: color[700],
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        elevation: 0,
      ),
    );
  }

  /// Widget สำหรับแสดงรูปภาพ Header
  Widget _buildHeaderImage(String imageUrl) {
    return Card(
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Image.network(
            imageUrl,
            height: 250,
            width: double.infinity,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                height: 250,
                color: Colors.grey[200],
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'กำลังโหลดรูปภาพ...',
                        style: GoogleFonts.prompt(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Container(
                height: 250,
                color: Colors.grey[200],
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.image_not_supported_outlined,
                        color: Colors.grey[400], size: 60),
                    const SizedBox(height: 8),
                    Text(
                      'ไม่สามารถโหลดรูปภาพได้',
                      style: GoogleFonts.prompt(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          // ไอคอนซูมเพื่อบอกว่าสามารถกดดูได้
          Positioned(
            bottom: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(
                Icons.zoom_in,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ],
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
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.payments_outlined, 
                    color: Colors.green[700], size: 24),
                const SizedBox(width: 8),
                Text(
                  'ยอดชำระ',
                  style: GoogleFonts.prompt(
                    fontSize: 16, 
                    color: Colors.green[900],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '${NumberFormat("#,##0.00").format(amount)} ฿',
              style: GoogleFonts.prompt(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.green[800],
                height: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Widget สำหรับแสดงรายละเอียดอื่นๆ
  Widget _buildDetailsCard(String formattedDate) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'รายละเอียดใบเสร็จ',
              style: GoogleFonts.prompt(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              icon: Icons.store_mall_directory_outlined,
              title: 'ร้านค้า',
              value: widget.receiptData['storeName'] ?? 'ไม่ระบุ',
            ),
            const Divider(height: 24),
            _buildInfoRow(
              icon: Icons.description_outlined,
              title: 'รายละเอียด',
              value: widget.receiptData['description'] ?? '-',
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
              value: widget.receiptData['userEmail'] ?? '-',
            ),
            if (widget.receiptData['createdAt'] != null) ...[
              const Divider(height: 24),
              _buildInfoRow(
                icon: Icons.schedule_outlined,
                title: 'เวลาที่บันทึก',
                value: _formatCreatedDate(widget.receiptData['createdAt']),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// จัดรูปแบบวันที่สร้าง
  String _formatCreatedDate(dynamic createdAt) {
    if (createdAt is Timestamp) {
      final date = createdAt.toDate();
      return DateFormat('d MMMM yyyy, เวลา HH:mm', 'th').format(date);
    }
    return 'ไม่ระบุ';
  }

  /// Widget สำหรับสร้างแถวข้อมูลแต่ละรายการ
  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.grey[600], size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.prompt(
                  fontSize: 13,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: GoogleFonts.prompt(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}