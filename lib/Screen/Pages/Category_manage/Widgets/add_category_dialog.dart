// lib/Screen/Pages/Category_manage/Widgets/add_category_dialog.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AddCategoryDialog extends StatefulWidget {
  const AddCategoryDialog({super.key});

  @override
  State<AddCategoryDialog> createState() => _AddCategoryDialogState();
}

class _AddCategoryDialogState extends State<AddCategoryDialog> {
  final TextEditingController _categoryNameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _categoryNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'เพิ่มหมวดหมู่ใหม่',
        style: GoogleFonts.prompt(fontWeight: FontWeight.bold),
      ),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _categoryNameController,
          decoration: InputDecoration(
            labelText: 'ชื่อหมวดหมู่',
            hintText: 'เช่น อาหาร, ค่าเดินทาง, บันเทิง',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          style: GoogleFonts.prompt(),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'กรุณากรอกชื่อหมวดหมู่';
            }
            if (value.trim().length > 50) {
              return 'ชื่อหมวดหมู่ไม่ควรเกิน 50 ตัวอักษร';
            }
            return null;
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(); // Close dialog without returning value
          },
          child: Text(
            'ยกเลิก',
            style: GoogleFonts.prompt(color: Colors.grey[600]),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.of(context).pop(_categoryNameController.text.trim()); // Return category name
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            'เพิ่ม',
            style: GoogleFonts.prompt(),
          ),
        ),
      ],
    );
  }
}