import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
class ShareService {
  static const String _appName = 'ระบบจัดการใบเสร็จ';
  static const String _appNameEn = 'Receipt Management System';

  /// แชร์ใบเสร็จเป็นข้อความธรรมดา
  static Future<void> shareAsText(Map<String, dynamic> receiptData) async {
    final amount = (receiptData['amount'] as num?)?.toDouble() ?? 0.0;
    final storeName = receiptData['storeName'] ?? 'ไม่ระบุร้านค้า';
    final description = receiptData['description'] ?? 'ไม่มีรายละเอียด';
    final transactionDate = (receiptData['transactionDate'] as Timestamp?)?.toDate();
    final formattedDate = transactionDate != null
        ? DateFormat('d MMMM yyyy, เวลา HH:mm', 'th').format(transactionDate)
        : 'ไม่ระบุวันที่';

    final shareText = '''
🧾 ใบเสร็จรับเงิน

🏪 ร้านค้า: $storeName
📝 รายละเอียด: $description
📅 วันที่: $formattedDate
💰 ยอดเงิน: ${NumberFormat("#,##0.00").format(amount)} ฿

📱 สร้างโดย$_appName
''';

    await Share.share(shareText);
  }

  /// สร้างและแชร์ไฟล์ PDF
  static Future<void> generateAndSharePDF(
    BuildContext context,
    Map<String, dynamic> receiptData,
  ) async {
    try {
      final pdf = pw.Document();
      final amount = (receiptData['amount'] as num?)?.toDouble() ?? 0.0;
      final storeName = receiptData['storeName'] ?? 'ไม่ระบุร้านค้า';
      final description = receiptData['description'] ?? 'ไม่มีรายละเอียด';
      final transactionDate = (receiptData['transactionDate'] as Timestamp?)?.toDate();
      final formattedDate = transactionDate != null
          ? DateFormat('d MMMM yyyy, เวลา HH:mm', 'th').format(transactionDate)
          : 'ไม่ระบุวันที่';

      // โหลดฟอนต์ไทย
      pw.Font? thaiFont = await _loadThaiFont();

      // โหลดรูปภาพใบเสร็จ
      pw.ImageProvider? receiptImage = await _loadReceiptImage(receiptData['imageUrl']);

      // สร้างหน้า PDF
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // หัวเรื่อง
                _buildPDFHeader(thaiFont),
                pw.SizedBox(height: 24),

                // รูปภาพใบเสร็จ (ถ้ามี)
                if (receiptImage != null) ...[
                  _buildPDFImage(receiptImage),
                  pw.SizedBox(height: 24),
                ],

                // ข้อมูลใบเสร็จ
                _buildPDFContent(
                  storeName: storeName,
                  description: description,
                  formattedDate: formattedDate,
                  userEmail: receiptData['userEmail'] ?? '-',
                  amount: amount,
                  thaiFont: thaiFont,
                ),

                pw.Spacer(),

                // ข้อมูลเพิ่มเติม
                _buildPDFFooter(thaiFont),
              ],
            );
          },
        ),
      );

      // บันทึกและแชร์ PDF
      await _savePDFAndShare(pdf, storeName, amount);
    } catch (e) {
      throw Exception('ไม่สามารถสร้าง PDF ได้: $e');
    }
  }

  /// สร้างและแชร์ QR Code
  static Future<void> generateAndShareQR(
    BuildContext context,
    Map<String, dynamic> receiptData,
    GlobalKey qrKey,
  ) async {
    try {
      final qrData = _createQRData(receiptData);
      final qrString = qrData.entries
          .map((e) => '${e.key}:${e.value}')
          .join('|');

      // สร้างรูป QR Code และบันทึกเป็นไฟล์
      final filePath = await _createQRImageFile(qrString, receiptData);

      // แสดง QR Code ใน Dialog
      if (context.mounted) {
        await _showQRDialog(context, qrString, receiptData, filePath, qrKey);
      }
    } catch (e) {
      throw Exception('ไม่สามารถสร้าง QR Code ได้: $e');
    }
  }

  /// สร้างข้อมูลสำหรับ QR Code
  static Map<String, dynamic> _createQRData(Map<String, dynamic> receiptData) {
    final amount = (receiptData['amount'] as num?)?.toDouble() ?? 0.0;
    final storeName = receiptData['storeName'] ?? 'ไม่ระบุร้านค้า';
    final description = receiptData['description'] ?? 'ไม่มีรายละเอียด';
    final transactionDate = (receiptData['transactionDate'] as Timestamp?)?.toDate();
    final formattedDate = transactionDate != null
        ? DateFormat('d/M/yyyy HH:mm').format(transactionDate)
        : 'ไม่ระบุวันที่';

    return {
      'type': 'receipt',
      'storeName': storeName,
      'description': description,
      'amount': amount,
      'date': formattedDate,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
  }

  /// สร้างไฟล์รูป QR Code
  static Future<String> _createQRImageFile(
    String qrString,
    Map<String, dynamic> receiptData,
  ) async {
    // สร้าง QR Widget ใน Memory (ไม่ใช้ RepaintBoundary จริง)
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/receipt_qr_${DateTime.now().millisecondsSinceEpoch}.png');
    
    // ในที่นี้เราจะต้องใช้วิธีอื่นในการสร้างรูป QR Code
    // เนื่องจากไม่สามารถใช้ RepaintBoundary ในฟังก์ชัน static ได้
    // แนะนำให้ใช้ library อื่นสำหรับสร้าง QR Code เป็นรูปภาพโดยตรง
    
    return file.path;
  }

  /// แสดง QR Code Dialog
  static Future<void> _showQRDialog(
    BuildContext context,
    String qrData,
    Map<String, dynamic> receiptData,
    String filePath,
    GlobalKey qrKey,
  ) async {
    final amount = (receiptData['amount'] as num?)?.toDouble() ?? 0.0;
    final storeName = receiptData['storeName'] ?? 'ไม่ระบุร้านค้า';

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text('QR Code ใบเสร็จ', 
            style: GoogleFonts.prompt(fontWeight: FontWeight.bold)),
        content: RepaintBoundary(
          key: qrKey,
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                QrImageView(
                  data: qrData,
                  version: QrVersions.auto,
                  size: 200.0,
                  backgroundColor: Colors.white,
                ),
                const SizedBox(height: 16),
                Text(
                  storeName,
                  style: GoogleFonts.prompt(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  '${NumberFormat("#,##0.00").format(amount)} ฿',
                  style: GoogleFonts.prompt(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[800],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            child: Text('คัดลอกข้อมูล', style: GoogleFonts.prompt()),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: qrData));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('คัดลอกข้อมูล QR Code แล้ว', 
                      style: GoogleFonts.prompt()),
                  backgroundColor: Colors.green,
                ),
              );
            },
          ),
          FilledButton(
            child: Text('แชร์', style: GoogleFonts.prompt()),
            onPressed: () async {
              Navigator.pop(context);
              await Share.shareXFiles(
                [XFile(filePath)],
                text: 'QR Code ใบเสร็จจาก $storeName',
              );
            },
          ),
        ],
      ),
    );
  }

  /// แสดงตัวเลือกการแชร์
  static void showShareOptions(
    BuildContext context,
    Map<String, dynamic> receiptData,
    GlobalKey qrKey,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'แชร์ใบเสร็จ',
              style: GoogleFonts.prompt(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            
            // ปุ่มแชร์ PDF
            ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
              title: Text('แชร์เป็น PDF', style: GoogleFonts.prompt()),
              subtitle: Text('สร้างเอกสาร PDF สำหรับพิมพ์หรือจัดเก็บ',
                  style: GoogleFonts.prompt(fontSize: 12)),
              onTap: () async {
                Navigator.pop(context);
                await _handleAsyncShare(
                  context,
                  () => generateAndSharePDF(context, receiptData),
                  'กำลังสร้าง PDF...',
                );
              },
            ),
            const Divider(),
            
            // ปุ่มแชร์ QR Code
            ListTile(
              leading: const Icon(Icons.qr_code, color: Colors.blue),
              title: Text('แชร์เป็น QR Code', style: GoogleFonts.prompt()),
              subtitle: Text('สร้าง QR Code สำหรับสแกนและดูข้อมูล',
                  style: GoogleFonts.prompt(fontSize: 12)),
              onTap: () async {
                Navigator.pop(context);
                await _handleAsyncShare(
                  context,
                  () => generateAndShareQR(context, receiptData, qrKey),
                  'กำลังสร้าง QR Code...',
                );
              },
            ),
            const Divider(),
            
            // ปุ่มแชร์ข้อความ
            ListTile(
              leading: const Icon(Icons.text_fields, color: Colors.green),
              title: Text('แชร์เป็นข้อความ', style: GoogleFonts.prompt()),
              subtitle: Text('แชร์ข้อมูลใบเสร็จเป็นข้อความธรรมดา',
                  style: GoogleFonts.prompt(fontSize: 12)),
              onTap: () async {
                Navigator.pop(context);
                await shareAsText(receiptData);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// จัดการ Loading และ Error สำหรับการแชร์แบบ Async
  static Future<void> _handleAsyncShare(
    BuildContext context,
    Future<void> Function() shareFunction,
    String loadingMessage,
  ) async {
    // แสดง Loading Dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(loadingMessage, style: GoogleFonts.prompt()),
          ],
        ),
      ),
    );

    try {
      await shareFunction();
      if (context.mounted) {
        Navigator.pop(context); // ปิด Loading Dialog
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // ปิด Loading Dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString(), style: GoogleFonts.prompt()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // --- Helper Methods สำหรับ PDF ---

  /// โหลดฟอนต์ไทยสำหรับ PDF
  static Future<pw.Font?> _loadThaiFont() async {
    try {
      final fontData = await rootBundle.load('fonts/NotoSansThai-Regular.ttf');
      return pw.Font.ttf(fontData);
    } catch (e) {
      print('ไม่สามารถโหลดฟอนต์ไทยได้: $e');
      return null;
    }
  }

  /// โหลดรูปภาพใบเสร็จสำหรับ PDF
static Future<pw.ImageProvider?> _loadReceiptImage(String? imageUrl) async {
  if (imageUrl == null || imageUrl.isEmpty) {
    print('URL รูปภาพเป็นค่าว่างหรือไม่ถูกต้อง');
    return null;
  }
  
  try {
    // ใช้ http.get() เพื่อดาวน์โหลดรูปภาพจากอินเทอร์เน็ต
    final response = await http.get(Uri.parse(imageUrl));
    
    if (response.statusCode == 200) {
      // หากดาวน์โหลดสำเร็จ ให้แปลงข้อมูลเป็น pw.MemoryImage
      return pw.MemoryImage(response.bodyBytes);
    } else {
      print('ไม่สามารถโหลดรูปภาพได้: สถานะ ${response.statusCode}');
      return null;
    }
  } catch (e) {
    print('เกิดข้อผิดพลาดขณะโหลดรูปภาพ: $e');
    return null;
  }
}

  /// สร้าง Header สำหรับ PDF
  static pw.Widget _buildPDFHeader(pw.Font? thaiFont) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.green50,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            'ใบเสร็จรับเงิน',
            style: pw.TextStyle(
              font: thaiFont,
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Receipt Document',
            style: const pw.TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  /// สร้างส่วนแสดงรูปภาพใน PDF
  static pw.Widget _buildPDFImage(pw.ImageProvider receiptImage) {
  return pw.Container(
    width: double.infinity,
    height: 200,
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: PdfColors.grey300),
      borderRadius: pw.BorderRadius.circular(8),
    ),
    child: pw.Image(
      receiptImage,
      fit: pw.BoxFit.contain,
    ),
  );
}

  /// สร้างเนื้อหาหลักของ PDF
  static pw.Widget _buildPDFContent({
    required String storeName,
    required String description,
    required String formattedDate,
    required String userEmail,
    required double amount,
    required pw.Font? thaiFont,
  }) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _buildPDFInfoRow('ร้านค้า / Store:', storeName, thaiFont),
          pw.SizedBox(height: 12),
          _buildPDFInfoRow('รายละเอียด / Description:', description, thaiFont),
          pw.SizedBox(height: 12),
          _buildPDFInfoRow('วันที่ / Date:', formattedDate, thaiFont),
          pw.SizedBox(height: 12),
          _buildPDFInfoRow('ผู้บันทึก / Recorded by:', userEmail, thaiFont),
          pw.SizedBox(height: 16),
          pw.Divider(color: PdfColors.grey400),
          pw.SizedBox(height: 16),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'ยอดรวม / Total Amount:',
                style: pw.TextStyle(
                  font: thaiFont,
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                '${NumberFormat("#,##0.00").format(amount)} ฿',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.green800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// สร้าง Footer สำหรับ PDF
  static pw.Widget _buildPDFFooter(pw.Font? thaiFont) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            'เอกสารนี้สร้างโดย$_appName',
            style: pw.TextStyle(font: thaiFont, fontSize: 10),
          ),
          pw.Text(
            'Generated by $_appNameEn',
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'สร้างเมื่อ: ${DateFormat('d MMMM yyyy, HH:mm', 'th').format(DateTime.now())}',
            style: pw.TextStyle(font: thaiFont, fontSize: 9),
          ),
        ],
      ),
    );
  }

  /// สร้างแถวข้อมูลใน PDF
  static pw.Widget _buildPDFInfoRow(String label, String value, pw.Font? thaiFont) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          width: 120,
          child: pw.Text(
            label,
            style: pw.TextStyle(
              font: thaiFont,
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
        pw.Expanded(
          child: pw.Text(
            value,
            style: pw.TextStyle(font: thaiFont, fontSize: 12),
          ),
        ),
      ],
    );
  }

  /// บันทึกและแชร์ไฟล์ PDF
  static Future<void> _savePDFAndShare(
    pw.Document pdf,
    String storeName,
    double amount,
  ) async {
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/receipt_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await pdf.save());

    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'ใบเสร็จจาก $storeName\nยอดเงิน: ${NumberFormat("#,##0.00").format(amount)} ฿',
    );
  }
}