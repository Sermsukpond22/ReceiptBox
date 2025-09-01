import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class EditReceiptPage extends StatefulWidget {
  final Map<String, dynamic> receiptData;

  const EditReceiptPage({Key? key, required this.receiptData}) : super(key: key);

  @override
  State<EditReceiptPage> createState() => _EditReceiptPageState();
}

class _EditReceiptPageState extends State<EditReceiptPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _storeNameController;
  late TextEditingController _amountController;
  late TextEditingController _descriptionController;

  late DateTime _selectedDate;
  File? _imageFile; // สำหรับเก็บไฟล์รูปภาพใหม่ที่เลือก
  String? _existingImageUrl; // สำหรับเก็บ URL ของรูปภาพเดิม
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // --- กำหนดค่าเริ่มต้นให้กับ Controller และ State จากข้อมูลที่ได้รับมา ---
    _storeNameController = TextEditingController(text: widget.receiptData['storeName'] ?? '');
    _amountController = TextEditingController(text: (widget.receiptData['amount'] as num?)?.toString() ?? '0.0');
    _descriptionController = TextEditingController(text: widget.receiptData['description'] ?? '');
    _selectedDate = (widget.receiptData['transactionDate'] as Timestamp?)?.toDate() ?? DateTime.now();
    _existingImageUrl = widget.receiptData['imageUrl'];
  }

  @override
  void dispose() {
    // --- คืนค่า Controller เพื่อป้องกัน Memory Leaks ---
    _storeNameController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // --- ฟังก์ชันสำหรับเลือกรูปภาพ ---
  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  // --- ฟังก์ชันสำหรับเลือกวันและเวลา ---
  Future<void> _selectDateTime(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDate),
      );
      if (pickedTime != null) {
        setState(() {
          _selectedDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  // --- ฟังก์ชันสำหรับอัปเดตข้อมูลใบเสร็จ ---
  Future<void> _updateReceipt() async {
    if (!_formKey.currentState!.validate()) {
      return; // ถ้าข้อมูลในฟอร์มไม่ถูกต้อง ให้ออกจากฟังก์ชัน
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final docId = widget.receiptData['docId'] as String?;
      if (docId == null) throw Exception("ไม่พบรหัสเอกสาร");

      String? imageUrl = _existingImageUrl;

      // 1. ตรวจสอบว่ามีการเลือกรูปภาพใหม่หรือไม่
      if (_imageFile != null) {
        // 1.1 ถ้ามีรูปภาพเดิม ให้ลบออกจาก Storage ก่อน
        if (_existingImageUrl != null && _existingImageUrl!.isNotEmpty) {
           final oldRef = FirebaseStorage.instance.refFromURL(_existingImageUrl!);
           await oldRef.delete();
        }
        // 1.2 อัปโหลดรูปภาพใหม่
        final fileName = '${docId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final ref = FirebaseStorage.instance.ref().child('receipts').child(fileName);
        await ref.putFile(_imageFile!);
        imageUrl = await ref.getDownloadURL();
      }

      // 2. เตรียมข้อมูลที่จะอัปเดต
      final updatedData = {
        'storeName': _storeNameController.text.trim(),
        'amount': double.tryParse(_amountController.text) ?? 0.0,
        'description': _descriptionController.text.trim(),
        'transactionDate': Timestamp.fromDate(_selectedDate),
        'imageUrl': imageUrl,
        'updatedAt': FieldValue.serverTimestamp(), // เพิ่ม field เพื่อบอกว่าแก้ไขล่าสุดเมื่อไหร่
      };

      // 3. อัปเดตข้อมูลใน Firestore
      await FirebaseFirestore.instance.collection('receipts').doc(docId).update(updatedData);
      
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
             content: Text('อัปเดตข้อมูลสำเร็จ', style: GoogleFonts.prompt()),
             backgroundColor: Colors.green,
           ),
         );
         // กลับไปหน้าก่อนหน้า 2 ครั้ง (ปิดหน้า Edit และ Detail) เพื่อไปยังหน้ารายการ
         Navigator.of(context).pop();
         Navigator.of(context).pop();
      }

    } catch (e) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e', style: GoogleFonts.prompt()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        title: Text('แก้ไขใบเสร็จ', style: GoogleFonts.prompt(fontWeight: FontWeight.bold)),
      ),
      body: Stack(
        children: [
          Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- ส่วนแสดงและเลือกรูปภาพ ---
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      height: 250,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.grey[300]!)
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // แสดงรูปที่เลือกใหม่ หรือรูปเดิม หรือ Icon Placeholder
                          ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: _imageFile != null
                                ? Image.file(_imageFile!, width: double.infinity, fit: BoxFit.cover)
                                : (_existingImageUrl != null && _existingImageUrl!.isNotEmpty)
                                    ? Image.network(_existingImageUrl!, width: double.infinity, fit: BoxFit.cover)
                                    : const Icon(Icons.camera_alt_outlined, size: 60, color: Colors.grey),
                          ),
                          // Overlay สำหรับปุ่ม "เปลี่ยนรูป"
                           Positioned.fill(
                             child: Container(
                               decoration: BoxDecoration(
                                 color: Colors.black.withOpacity(0.3),
                                 borderRadius: BorderRadius.circular(15),
                               ),
                               child: Center(
                                 child: Row(
                                   mainAxisAlignment: MainAxisAlignment.center,
                                   children: [
                                     const Icon(Icons.edit, color: Colors.white),
                                     const SizedBox(width: 8),
                                     Text('เปลี่ยนรูปภาพ', style: GoogleFonts.prompt(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                   ],
                                 ),
                               ),
                             ),
                           )
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- ฟอร์มกรอกข้อมูล ---
                  _buildTextFormField(
                    controller: _storeNameController,
                    labelText: 'ร้านค้า',
                    icon: Icons.store_mall_directory_outlined,
                    validator: (value) => (value == null || value.isEmpty) ? 'กรุณากรอกชื่อร้านค้า' : null,
                  ),
                  const SizedBox(height: 16),
                  _buildTextFormField(
                     controller: _amountController,
                     labelText: 'ยอดชำระ (บาท)',
                     icon: Icons.monetization_on_outlined,
                     keyboardType: const TextInputType.numberWithOptions(decimal: true),
                     validator: (value) {
                       if (value == null || value.isEmpty) return 'กรุณากรอกยอดชำระ';
                       if (double.tryParse(value) == null) return 'กรุณากรอกตัวเลขที่ถูกต้อง';
                       return null;
                     },
                  ),
                  const SizedBox(height: 16),
                  
                  // --- ส่วนเลือกวันที่ ---
                  Card(
                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                     elevation: 0,
                     color: Colors.white,
                     child: ListTile(
                       leading: const Icon(Icons.calendar_today_outlined, color: Colors.grey),
                       title: Text(
                         'วันที่ทำรายการ',
                         style: GoogleFonts.prompt(fontSize: 12, color: Colors.grey[600]),
                       ),
                       subtitle: Text(
                         DateFormat('d MMMM yyyy, HH:mm', 'th').format(_selectedDate),
                         style: GoogleFonts.prompt(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black),
                       ),
                       onTap: () => _selectDateTime(context),
                       trailing: const Icon(Icons.arrow_drop_down),
                     ),
                  ),
                  const SizedBox(height: 16),
                  _buildTextFormField(
                    controller: _descriptionController,
                    labelText: 'รายละเอียดเพิ่มเติม (ไม่บังคับ)',
                    icon: Icons.description_outlined,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 32),

                  // --- ปุ่มบันทึก ---
                  FilledButton.icon(
                    icon: const Icon(Icons.save_as_outlined),
                    label: Text('บันทึกการเปลี่ยนแปลง', style: GoogleFonts.prompt(fontSize: 16, fontWeight: FontWeight.bold)),
                    onPressed: _isLoading ? null : _updateReceipt, // ปิดปุ่มขณะโหลด
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // --- Loading Overlay ---
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  // --- Helper Widget สำหรับสร้าง TextFormField ---
  Widget _buildTextFormField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    TextInputType? keyboardType,
    int? maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: GoogleFonts.prompt(),
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: GoogleFonts.prompt(),
        prefixIcon: Icon(icon, color: Colors.grey[600]),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
      validator: validator,
    );
  }
}