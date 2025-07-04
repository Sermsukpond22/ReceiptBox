import 'package:flutter/material.dart';
//import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:run_android/services/receipt_ocr_result.dart'; // Import a- OCR result model

class UiUtils {
  // --- SNACKBARS ---
  static void showSuccessSnackBar(BuildContext context, String message) {
    if (!context.mounted) return;
    _showSnackBar(context, message, Icons.check_circle, Colors.green);
  }

  static void showInfoSnackBar(BuildContext context, String message) {
    if (!context.mounted) return;
    _showSnackBar(context, message, Icons.info, Colors.blue);
  }

  static void _showSnackBar(BuildContext context, String message, IconData icon, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 8),
          Expanded(child: Text(message)),
        ]),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // --- GENERAL DIALOGS ---

  static Future<T?> _showAppDialog<T>({
    required BuildContext context,
    required String title,
    required Widget content,
    required IconData icon,
    required Color iconColor,
    List<Widget>? actions,
  }) {
    if (!context.mounted) return Future.value();
    return showDialog<T>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(width: 8),
          Text(title),
        ]),
        content: content,
        actions: actions ?? [
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('ตกลง'),
          ),
        ],
      ),
    );
  }

  static Future<void> showErrorDialog(BuildContext context, String message) =>
      _showAppDialog(
        context: context,
        title: 'เกิดข้อผิดพลาด',
        content: Text(message),
        icon: Icons.error,
        iconColor: Colors.red,
      );

  static Future<void> showWarningDialog(BuildContext context, String message) =>
      _showAppDialog(
        context: context,
        title: 'คำเตือน',
        content: Text(message),
        icon: Icons.warning,
        iconColor: Colors.orange,
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('เข้าใจแล้ว'),
          ),
        ]
      );

  // --- CONFIRMATION DIALOGS ---

  static Future<bool?> showSaveConfirmation(BuildContext context) {
    return _showAppDialog<bool>(
      context: context,
      title: 'ยืนยันการบันทึก',
      content: const Text('คุณต้องการบันทึกข้อมูลใบเสร็จนี้หรือไม่?'),
      icon: Icons.save_alt_outlined,
      iconColor: Colors.green,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('ยกเลิก'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
          child: const Text('บันทึก'),
        ),
      ],
    );
  }

  static Future<bool?> showClearConfirmation(BuildContext context) {
    return _showAppDialog<bool>(
      context: context,
      title: 'ยืนยันการล้างข้อมูล',
      content: const Text('คุณต้องการล้างข้อมูลทั้งหมดหรือไม่?\nข้อมูลที่กรอกไว้จะหายไป'),
      icon: Icons.delete_sweep_outlined,
      iconColor: Colors.red,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('ยกเลิก'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
          child: const Text('ล้างข้อมูล'),
        ),
      ],
    );
  }

  // --- SPECIFIC DIALOGS ---
  
  static Future<void> showSaveSuccessDialog(BuildContext context) async {
    await _showAppDialog(
      context: context,
      title: 'บันทึกสำเร็จ!',
      content: const Text('ใบเสร็จของคุณถูกบันทึกเรียบร้อยแล้ว'),
      icon: Icons.check_circle,
      iconColor: Colors.green,
      actions: [
        ElevatedButton(
          onPressed: () {
            if (!context.mounted) return;
            Navigator.of(context).pop(); // Close dialog
            Navigator.of(context).pop(); // Go back to previous page
          },
          child: const Text('ตกลง'),
        ),
      ],
    );
  }

  static Future<void> showScanResultDialog(BuildContext context, ReceiptOCRResult result) {
    return _showAppDialog(
      context: context,
      title: 'สแกนสำเร็จ!',
      icon: Icons.check_circle,
      iconColor: Colors.green,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ข้อมูลที่สแกนได้ (ความแม่นยำ: ${(result.confidence * 100).toStringAsFixed(0)}%):'),
          const SizedBox(height: 12),
          if (result.storeName.isNotEmpty) ...[
            Text('• ร้านค้า: ${result.storeName}'),
            const SizedBox(height: 4),
          ],
          if (result.amount != null) ...[
            Text('• จำนวนเงิน: ${result.amount!.toStringAsFixed(2)} บาท'),
            const SizedBox(height: 4),
          ],
          if (result.date != null) ...[
            Text('• วันที่: ${DateFormat('dd/MM/yyyy').format(result.date!)}'),
            const SizedBox(height: 4),
          ],
          const SizedBox(height: 12),
          Text(
            'ข้อมูลได้ถูกกรอกลงในฟอร์มแล้ว คุณสามารถแก้ไขได้ตามต้องการ',
            style: TextStyle(fontSize: 12, color: Colors.grey[600], fontStyle: FontStyle.italic),
          ),
        ],
      ),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('เข้าใจแล้ว'),
        ),
      ],
    );
  }
  
  static Future<void> showHelpDialog(BuildContext context) {
    return _showAppDialog(
      context: context,
      title: 'คำแนะนำการใช้งาน',
      icon: Icons.help_outline,
      iconColor: Colors.blue,
      content: const SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('📱 สแกนใบเสร็จอัตโนมัติ:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('• ใช้ AI ช่วยดึงข้อมูลจากรูปภาพ\n• ถ่ายรูปใบเสร็จให้ชัดเจนและอยู่ในกรอบ'),
            SizedBox(height: 12),
            Text('✏️ กรอกข้อมูลด้วยตนเอง:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('• "วันที่" และ "จำนวนเงิน" เป็นข้อมูลที่จำเป็น\n• ตรวจสอบข้อมูลก่อนกดบันทึก'),
            SizedBox(height: 12),
            Text('📸 รูปภาพใบเสร็จ:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('• สามารถแนบรูปภาพเพื่อใช้อ้างอิงภายหลังได้\n• ไม่บังคับ แต่แนะนำเพื่อความสะดวก'),
          ],
        ),
      ),
    );
  }
  
  static Future<String?> showSaveSuccessChoiceDialog(BuildContext context) {
    return _showAppDialog<String>(
      context: context,
      title: 'บันทึกสำเร็จ!',
      content: const Text('คุณต้องการเพิ่มใบเสร็จใหม่ หรือไปหน้ารายการใบเสร็จ?'),
      icon: Icons.check_circle,
      iconColor: Colors.green,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop('/add_receipt'),
          child: const Text('เพิ่มใบเสร็จใหม่'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop('/document'),
          child: const Text('ไปหน้ารายการใบเสร็จ'),
        ),
      ],
    );
  }

  
  // --- BOTTOM SHEETS ---

  static Future<void> showImageSourceBottomSheet({
    required BuildContext context,
    required bool hasImage,
    required VoidCallback onCamera,
    required VoidCallback onGallery,
    required VoidCallback onRemove,
  }) {
    return showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Text('เลือกรูปภาพใบเสร็จ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined, color: Colors.blue),
              title: const Text('ถ่ายรูป'),
              onTap: () { Navigator.pop(ctx); onCamera(); },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: Colors.green),
              title: const Text('เลือกจากคลังภาพ'),
              onTap: () { Navigator.pop(ctx); onGallery(); },
            ),
            if (hasImage)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('ลบรูปภาพ'),
                onTap: () { Navigator.pop(ctx); onRemove(); },
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // --- OVERLAYS ---

  static Widget buildLoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('กำลังบันทึกข้อมูล...', style: TextStyle(fontSize: 16)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}