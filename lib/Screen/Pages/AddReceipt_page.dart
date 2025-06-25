// add_receipt_page.dart (Updated version with Cool Alert)
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cool_alert/cool_alert.dart';
import 'package:run_android/services/receipt_service.dart'; // เพิ่ม import สำหรับ Cool Alert


class AddReceiptPage extends StatefulWidget {
  const AddReceiptPage({super.key});

  @override
  State<AddReceiptPage> createState() => _AddReceiptPageState();
}

class _AddReceiptPageState extends State<AddReceiptPage> {
  // State variables
  bool _isProcessing = false;
  File? _imageFile;

  // Controllers สำหรับ TextField
  final _storeController = TextEditingController();
  final _dateController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  // Instance ของ Service และ ImagePicker
  final ReceiptService _receiptService = ReceiptService();
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _storeController.dispose();
    _dateController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // ฟังก์ชันสำหรับเลือกรูปภาพ
  Future<void> _showImageSourceDialog() async {
    showModalBottomSheet(
      context: context,
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
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.green),
              title: const Text('เลือกจากคลังภาพ'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            if (_imageFile != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('ลบรูปภาพ'),
                onTap: () {
                  Navigator.pop(context);
                  _removeImage();
                },
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ฟังก์ชันสำหรับเลือกรูปภาพ
  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
        
        // แสดง Cool Alert เมื่อเลือกรูปสำเร็จ
        CoolAlert.show(
          context: context,
          type: CoolAlertType.success,
          title: "สำเร็จ!",
          text: "เพิ่มรูปภาพใบเสร็จเรียบร้อยแล้ว",
          autoCloseDuration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      _showErrorAlert('เกิดข้อผิดพลาดในการเลือกรูปภาพ: $e');
    }
  }

  // ฟังก์ชันสำหรับลบรูปภาพ
  void _removeImage() {
    setState(() {
      _imageFile = null;
    });
    
    // แสดง Cool Alert เมื่อลบรูปสำเร็จ
    CoolAlert.show(
      context: context,
      type: CoolAlertType.info,
      title: "ลบรูปภาพแล้ว",
      text: "รูปภาพใบเสร็จถูกลบออกแล้ว",
      autoCloseDuration: const Duration(seconds: 2),
    );
  }

  // ฟังก์ชันสำหรับเลือกวันที่
  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    
    if (picked != null) {
      setState(() {
        _dateController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  // ฟังก์ชันสำหรับแสดง Confirmation Alert ก่อนบันทึก
  Future<void> _showSaveConfirmation() async {
    CoolAlert.show(
      context: context,
      type: CoolAlertType.confirm,
      title: "ยืนยันการบันทึก",
      text: "คุณต้องการบันทึกข้อมูลใบเสร็จนี้หรือไม่?",
      confirmBtnText: "บันทึก",
      cancelBtnText: "ยกเลิก",
      confirmBtnColor: Colors.green,
      onConfirmBtnTap: () {
        Navigator.of(context).pop(); // ปิด dialog
        _saveReceipt(); // เรียก function บันทึก
      },
    );
  }

  // ฟังก์ชันสำหรับแสดง Confirmation Alert ก่อนล้างข้อมูล
  Future<void> _showClearConfirmation() async {
    CoolAlert.show(
      context: context,
      type: CoolAlertType.warning,
      title: "ยืนยันการล้างข้อมูล",
      text: "คุณต้องการล้างข้อมูลทั้งหมดหรือไม่?\nข้อมูลที่กรอกไว้จะหายไป",
      confirmBtnText: "ล้างข้อมูล",
      cancelBtnText: "ยกเลิก",
      confirmBtnColor: Colors.red,
      onConfirmBtnTap: () {
        Navigator.of(context).pop(); // ปิด dialog
        _clearForm(); // เรียก function ล้างข้อมูล
      },
    );
  }

  // ฟังก์ชันบันทึกข้อมูล (ใช้ Service)
  Future<void> _saveReceipt() async {
    // ตรวจสอบการเข้าสู่ระบบ
    if (!_receiptService.isUserLoggedIn) {
      _showErrorAlert('กรุณาเข้าสู่ระบบก่อนใช้งาน');
      return;
    }

    // ตรวจสอบข้อมูลพื้นฐาน
    if (_amountController.text.isEmpty || _dateController.text.isEmpty) {
      _showWarningAlert('กรุณากรอกวันที่และจำนวนเงิน');
      return;
    }

    // ตรวจสอบจำนวนเงิน
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      _showWarningAlert('กรุณากรอกจำนวนเงินที่ถูกต้อง');
      return;
    }

    // ตรวจสอบรูปแบบวันที่
    DateTime? date;
    try {
      date = DateFormat('dd/MM/yyyy').parse(_dateController.text);
    } catch (e) {
      _showWarningAlert('กรุณากรอกวันที่ในรูปแบบ วว/ดด/ปปปป');
      return;
    }

    // สร้าง ReceiptData object
    final receiptData = ReceiptData(
      storeName: _storeController.text,
      description: _descriptionController.text,
      amount: amount,
      transactionDate: date,
      imageFile: _imageFile,
    );

    // ตรวจสอบความถูกต้องของข้อมูล
    final validationError = ReceiptService.validateReceiptData(receiptData);
    if (validationError != null) {
      _showWarningAlert(validationError);
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      // บันทึกข้อมูลผ่าน Service
      await _receiptService.saveReceipt(receiptData);

      // แสดง Success Alert
      CoolAlert.show(
        context: context,
        type: CoolAlertType.success,
        title: "บันทึกสำเร็จ!",
        text: "ใบเสร็จของคุณถูกบันทึกเรียบร้อยแล้ว",
        confirmBtnText: "ตกลง",
        onConfirmBtnTap: () {
          Navigator.of(context).pop(); // ปิด alert
          Navigator.of(context).pop(); // กลับไปหน้าก่อนหน้า
        },
      );

    } catch (e) {
      _showErrorAlert(e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  // ฟังก์ชันสำหรับล้างข้อมูลในฟอร์ม
  void _clearForm() {
    _storeController.clear();
    _dateController.clear();
    _amountController.clear();
    _descriptionController.clear();
    _removeImage();
    
    // แสดง Info Alert เมื่อล้างข้อมูลสำเร็จ
    CoolAlert.show(
      context: context,
      type: CoolAlertType.info,
      title: "ล้างข้อมูลแล้ว",
      text: "ข้อมูลทั้งหมดถูกล้างเรียบร้อยแล้ว",
      autoCloseDuration: const Duration(seconds: 2),
    );
  }

  // Helper functions สำหรับแสดง Cool Alert
  void _showSuccessAlert(String message) {
    CoolAlert.show(
      context: context,
      type: CoolAlertType.success,
      title: "สำเร็จ!",
      text: message,
      autoCloseDuration: const Duration(seconds: 3),
    );
  }

  void _showErrorAlert(String message) {
    CoolAlert.show(
      context: context,
      type: CoolAlertType.error,
      title: "เกิดข้อผิดพลาด",
      text: message,
      confirmBtnText: "ตกลง",
    );
  }

  void _showWarningAlert(String message) {
    CoolAlert.show(
      context: context,
      type: CoolAlertType.warning,
      title: "คำเตือน",
      text: message,
      confirmBtnText: "เข้าใจแล้ว",
    );
  }

  void _showInfoAlert(String message) {
    CoolAlert.show(
      context: context,
      type: CoolAlertType.info,
      title: "ข้อมูล",
      text: message,
      confirmBtnText: "ตกลง",
    );
  }

  // ฟังก์ชันสำหรับแสดงข้อมูลช่วยเหลือ
  void _showHelpDialog() {
    CoolAlert.show(
      context: context,
      type: CoolAlertType.info,
      title: "คำแนะนำการใช้งาน",
      text: "• กรอกข้อมูลใบเสร็จให้ครบถ้วน\n• วันที่และจำนวนเงินเป็นข้อมูลที่จำเป็น\n• สามารถเพิ่มรูปภาพใบเสร็จได้\n• ตรวจสอบข้อมูลก่อนบันทึก",
      confirmBtnText: "เข้าใจแล้ว",
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('เพิ่มใบเสร็จ'),
        actions: [
          // ปุ่มสำหรับช่วยเหลือ
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showHelpDialog,
            tooltip: 'ช่วยเหลือ',
          ),
          // ปุ่มสำหรับเลือกรูปภาพ
          IconButton(
            icon: const Icon(Icons.add_a_photo),
            onPressed: _showImageSourceDialog,
            tooltip: 'เลือกรูปภาพ',
          ),
          // ปุ่มสำหรับล้างข้อมูล
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: _showClearConfirmation,
            tooltip: 'ล้างข้อมูล',
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
                // ส่วนแสดงรูปภาพ
                GestureDetector(
                  onTap: _showImageSourceDialog,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: _imageFile != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              _imageFile!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_a_photo,
                                size: 50,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'แตะเพื่อเลือกรูปภาพใบเสร็จ',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '(ไม่บังคับ)',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),

                // ส่วนหัวของฟอร์ม
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Icon(
                          Icons.receipt_long,
                          size: 50,
                          color: Theme.of(context).primaryColor,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'กรอกข้อมูลใบเสร็จ',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'กรุณากรอกข้อมูลใบเสร็จอย่างครบถ้วน',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),

                // ฟอร์มสำหรับกรอกข้อมูล
                TextField(
                  controller: _storeController,
                  decoration: const InputDecoration(
                    labelText: 'ชื่อร้านค้า/บริการ',
                    prefixIcon: Icon(Icons.store),
                    border: OutlineInputBorder(),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                TextField(
                  controller: _dateController,
                  decoration: InputDecoration(
                    labelText: 'วันที่ (วว/ดด/ปปปป)',
                    prefixIcon: const Icon(Icons.calendar_today),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.date_range),
                      onPressed: _selectDate,
                    ),
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.datetime,
                  onTap: _selectDate,
                  readOnly: true,
                ),
                
                const SizedBox(height: 16),
                
                TextField(
                  controller: _amountController,
                  decoration: const InputDecoration(
                    labelText: 'จำนวนเงิน (บาท)',
                    prefixIcon: Icon(Icons.monetization_on),
                    border: OutlineInputBorder(),
                    helperText: 'ตัวอย่าง: 100.50',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                
                const SizedBox(height: 16),
                
                TextField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'คำอธิบาย/รายการ',
                    prefixIcon: Icon(Icons.description),
                    border: OutlineInputBorder(),
                    helperText: 'รายละเอียดเพิ่มเติม (ไม่บังคับ)',
                  ),
                  maxLines: 3,
                ),
                
                const SizedBox(height: 32),
                
                // ปุ่มบันทึกข้อมูล
                ElevatedButton.icon(
                  onPressed: _isProcessing ? null : _showSaveConfirmation,
                  icon: const Icon(Icons.save),
                  label: const Text('บันทึกข้อมูล'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // ปุ่มล้างข้อมูล
                OutlinedButton.icon(
                  onPressed: _isProcessing ? null : _showClearConfirmation,
                  icon: const Icon(Icons.clear),
                  label: const Text('ล้างข้อมูล'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
              ],
            ),
          ),
          
          // Loading Overlay
          if (_isProcessing)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'กำลังบันทึกข้อมูล...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}