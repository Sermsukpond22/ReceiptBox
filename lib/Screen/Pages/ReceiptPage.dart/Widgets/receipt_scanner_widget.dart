// widgets/receipt_scanner_widget.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:run_android/services/receipt_ocr_result.dart';
import 'package:run_android/services/vision_ocr_service.dart';


class ReceiptScannerWidget extends StatefulWidget {
  final Function(ReceiptOCRResult) onScanComplete;
  final VoidCallback? onScanStart;
  final Function(String)? onError;

  const ReceiptScannerWidget({
    super.key,
    required this.onScanComplete,
    this.onScanStart,
    this.onError,
  });

  @override
  State<ReceiptScannerWidget> createState() => _ReceiptScannerWidgetState();
}

class _ReceiptScannerWidgetState extends State<ReceiptScannerWidget> {
  final GoogleVisionService _visionService = GoogleVisionService();
  final ImagePicker _picker = ImagePicker();
  
  ScanResult _scanResult = ScanResult.idle();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildScanButton(),
            const SizedBox(height: 16),
            _buildStatusWidget(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Icon(
          Icons.document_scanner,
          size: 32,
          color: Theme.of(context).primaryColor,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'สแกนใบเสร็จอัตโนมัติ',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'ใช้ AI ช่วยดึงข้อมูลจากใบเสร็จ',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildScanButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _scanResult.isScanning ? null : _showImageSourceDialog,
        icon: _scanResult.isScanning
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.document_scanner),
        label: Text(
          _scanResult.isScanning ? 'กำลังสแกน...' : 'สแกนใบเสร็จ',
        ),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusWidget() {
    switch (_scanResult.status) {
      case ScanStatus.idle:
        return _buildIdleStatus();
      case ScanStatus.scanning:
        return _buildScanningStatus();
      case ScanStatus.success:
        return _buildSuccessStatus();
      case ScanStatus.error:
        return _buildErrorStatus();
    }
  }

  Widget _buildIdleStatus() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.blue[700]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'เลือกรูปภาพใบเสร็จเพื่อเริ่มสแกน',
              style: TextStyle(color: Colors.blue[700]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanningStatus() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.orange[700],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'กำลังวิเคราะห์ใบเสร็จด้วย AI...',
              style: TextStyle(color: Colors.orange[700]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessStatus() {
    final result = _scanResult.result!;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green[700]),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'สแกนสำเร็จ! (ความแม่นยำ: ${(result.confidence * 100).toStringAsFixed(0)}%)',
                  style: TextStyle(
                    color: Colors.green[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildResultDetails(result),
        ],
      ),
    );
  }

  Widget _buildErrorStatus() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red[700]),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'เกิดข้อผิดพลาดในการสแกน',
                  style: TextStyle(
                    color: Colors.red[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
                      Text(
            _scanResult.errorMessage ?? 'ไม่สามารถสแกนใบเสร็จได้',
            style: TextStyle(color: Colors.red[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildResultDetails(ReceiptOCRResult result) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (result.storeName.isNotEmpty)
          _buildDetailRow('ร้านค้า:', result.storeName),
        if (result.amount != null)
          _buildDetailRow('จำนวนเงิน:', '${result.amount!.toStringAsFixed(2)} บาท'),
        if (result.date != null)
          _buildDetailRow('วันที่:', _formatDate(result.date!)),
        if (result.description.isNotEmpty)
          _buildDetailRow('รายการ:', result.description),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Future<void> _showImageSourceDialog() async {
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'เลือกรูปภาพใบเสร็จ',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.blue),
              title: const Text('ถ่ายรูป'),
              onTap: () {
                Navigator.pop(context);
                _scanFromCamera();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.green),
              title: const Text('เลือกจากคลังภาพ'),
              onTap: () {
                Navigator.pop(context);
                _scanFromGallery();
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _scanFromCamera() async {
    await _scanImage(ImageSource.camera);
  }

  Future<void> _scanFromGallery() async {
    await _scanImage(ImageSource.gallery);
  }

  Future<void> _scanImage(ImageSource source) async {
    try {
      // เลือกรูปภาพ
      final pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      // เริ่มสแกน
      setState(() {
        _scanResult = ScanResult.scanning();
      });

      widget.onScanStart?.call();

      // สแกนด้วย Google Vision API
      final result = await _visionService.scanReceipt(File(pickedFile.path));

      setState(() {
        _scanResult = ScanResult.success(result);
      });

      // ส่งผลลัพธ์กลับ
      widget.onScanComplete(result);

    } catch (e) {
      final errorMessage = 'ไม่สามารถสแกนใบเสร็จได้: $e';
      
      setState(() {
        _scanResult = ScanResult.error(errorMessage);
      });

      widget.onError?.call(errorMessage);
    }
  }

  void resetScanResult() {
    setState(() {
      _scanResult = ScanResult.idle();
    });
  }
}