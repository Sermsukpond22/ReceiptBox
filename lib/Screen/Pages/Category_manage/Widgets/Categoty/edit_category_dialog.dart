// edit_category_dialog.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:run_android/models/category_model.dart';

class CategoryManagementDialog extends StatefulWidget {
  final Category category;

  const CategoryManagementDialog({
    Key? key,
    required this.category,
  }) : super(key: key);

  @override
  State<CategoryManagementDialog> createState() => _CategoryManagementDialogState();
}

class _CategoryManagementDialogState extends State<CategoryManagementDialog> {
  final TextEditingController _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // Use the icon from the category model as the initial selected icon
  IconData? _selectedIcon;

  final List<IconData> _icons = [
    Icons.water, // ค่าน้ำ
    Icons.lightbulb_outline, // ค่าไฟ
    Icons.local_gas_station, // ค่าน้ำมัน
    Icons.store, // ร้านสะดวกซื้อ
    Icons.local_grocery_store, // ซุปเปอร์มาเก็ต
  ];

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.category.name;
    // Set the initial selected icon from the category model
    _selectedIcon = widget.category.icon;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  
  // Method to update the category in Firestore
  Future<void> _updateCategory() async {
    if (_formKey.currentState!.validate() && _selectedIcon != null) {
      try {
        await FirebaseFirestore.instance
            .collection('categories')
            .doc(widget.category.id)
            .update({
              'name': _nameController.text.trim(),
              'icon': _selectedIcon!.codePoint, // Save icon as code point
            });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('แก้ไขหมวดหมู่สำเร็จ', style: GoogleFonts.prompt())),
        );
        Navigator.of(context).pop();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการแก้ไข: $e', style: GoogleFonts.prompt())),
        );
      }
    } else if (_selectedIcon == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'กรุณาเลือกไอคอน',
            style: GoogleFonts.prompt(),
          ),
        ),
      );
    }
  }

  // Method to delete the category
  Future<void> _deleteCategory() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(
            'ยืนยันการลบ',
            style: GoogleFonts.prompt(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                  'คุณต้องการลบหมวดหมู่ "${widget.category.name}" ใช่หรือไม่? การกระทำนี้ไม่สามารถย้อนกลับได้',
                  style: GoogleFonts.prompt(),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'ยกเลิก',
                style: GoogleFonts.prompt(color: Colors.grey[600]),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: Text(
                'ลบ',
                style: GoogleFonts.prompt(color: Colors.red),
              ),
              onPressed: () async {
                try {
                  await FirebaseFirestore.instance
                      .collection('categories')
                      .doc(widget.category.id)
                      .delete();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('ลบหมวดหมู่สำเร็จ', style: GoogleFonts.prompt())),
                  );
                  Navigator.of(dialogContext).pop();
                  Navigator.of(context).pop();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('เกิดข้อผิดพลาดในการลบ: $e', style: GoogleFonts.prompt())),
                  );
                  Navigator.of(dialogContext).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'แก้ไขหมวดหมู่',
        style: GoogleFonts.prompt(fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'ชื่อหมวดหมู่',
                  labelStyle: GoogleFonts.prompt(color: Colors.grey[600]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                style: GoogleFonts.prompt(),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'กรุณาใส่ชื่อหมวดหมู่';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              Text(
                'เลือกไอคอนสำหรับหมวดหมู่',
                style: GoogleFonts.prompt(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _icons.map((icon) {
                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedIcon = icon;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _selectedIcon == icon
                            ? Theme.of(context).primaryColor
                            : Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        icon,
                        color: _selectedIcon == icon
                            ? Colors.white
                            : Theme.of(context).primaryColor,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: Text(
            'ลบ',
            style: GoogleFonts.prompt(color: Colors.red),
          ),
          onPressed: _deleteCategory,
        ),
        TextButton(
          child: Text(
            'ยกเลิก',
            style: GoogleFonts.prompt(color: Colors.grey[600]),
          ),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
          ),
          child: Text(
            'บันทึก',
            style: GoogleFonts.prompt(color: Colors.white),
          ),
          onPressed: _updateCategory,
        ),
      ],
      
    );
  }
}