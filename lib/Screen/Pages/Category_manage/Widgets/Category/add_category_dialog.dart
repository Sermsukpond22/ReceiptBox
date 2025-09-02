// lib/Screen/Pages/Category_manage/Widgets/add_category_dialog.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cool_alert/cool_alert.dart';
// ✅ Import model เข้ามาเพื่อใช้ availableIcons และฟังก์ชัน
import 'package:run_android/models/category_model.dart';
import 'package:run_android/services/categories_service.dart';

class AddCategoryDialog extends StatefulWidget {
  const AddCategoryDialog({Key? key}) : super(key: key);

  @override
  State<AddCategoryDialog> createState() => _AddCategoryDialogState();
}

class _AddCategoryDialogState extends State<AddCategoryDialog> {
  final TextEditingController _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final CategoryService _categoryService = CategoryService();

  // State จะเก็บ "ชื่อไอคอนภาษาอังกฤษ" เช่น 'category' เป็นค่าเริ่มต้น
  String _selectedIcon = 'category';
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _showIconPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('เลือกไอคอน', style: GoogleFonts.prompt(fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: double.maxFinite,
          child: GridView.builder(
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: availableIcons.length,
            itemBuilder: (context, index) {
              final entry = availableIcons.entries.elementAt(index);
              final displayName = entry.key;
              final iconData = entry.value;
              final iconKey = Category.getIconName(iconData);
              final isSelected = iconKey == _selectedIcon;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedIcon = iconKey;
                  });
                  Navigator.of(context).pop();
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? Colors.blue : Colors.grey.shade300,
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(iconData, size: 28, color: isSelected ? Colors.blue : Colors.grey.shade700),
                      const SizedBox(height: 4),
                      Text(
                        displayName,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.prompt(fontSize: 10, color: isSelected ? Colors.blue : Colors.grey.shade600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('ปิด', style: GoogleFonts.prompt()),
          ),
        ],
      ),
    );
  }

  Future<void> _createCategory() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await _categoryService.createCategory(
        _nameController.text.trim(),
        icon: _selectedIcon, // ✅ ส่งชื่อภาษาอังกฤษไปสร้าง
      );
      Navigator.of(context).pop(); // ปิด dialog
      CoolAlert.show(
        context: context,
        type: CoolAlertType.success,
        title: 'สำเร็จ!',
        text: 'เพิ่มหมวดหมู่ใหม่เรียบร้อยแล้ว',
        confirmBtnText: 'ตกลง',
        confirmBtnTextStyle: GoogleFonts.prompt(color: Colors.white),
      );
    } catch (e) {
      CoolAlert.show(
        context: context,
        type: CoolAlertType.error,
        title: 'เกิดข้อผิดพลาด',
        text: 'ไม่สามารถสร้างหมวดหมู่ได้: $e',
        confirmBtnText: 'ตกลง',
        confirmBtnTextStyle: GoogleFonts.prompt(color: Colors.white),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('เพิ่มหมวดหมู่ใหม่', style: GoogleFonts.prompt(fontWeight: FontWeight.bold)),
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
                  prefixIcon: Icon(
                    Category.getIconFromName(_selectedIcon),
                    color: Colors.blue,
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'กรุณากรอกชื่อหมวดหมู่';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _showIconPicker,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Category.getIconFromName(_selectedIcon),
                            color: Colors.blue,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'เลือกไอคอน',
                            style: GoogleFonts.prompt(fontSize: 16),
                          ),
                        ],
                      ),
                      const Icon(Icons.arrow_drop_down),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: Text('ยกเลิก', style: GoogleFonts.prompt(color: Colors.grey[600])),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _createCategory,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue.shade600,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 16, height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                )
              : Text('บันทึก', style: GoogleFonts.prompt(fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}