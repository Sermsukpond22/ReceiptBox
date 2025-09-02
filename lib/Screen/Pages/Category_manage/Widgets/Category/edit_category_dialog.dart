// lib/Screen/Pages/Category_manage/Widgets/edit_category_dialog.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cool_alert/cool_alert.dart';
import 'package:run_android/models/category_model.dart';
import 'package:run_android/services/categories_service.dart';

class EditCategoryDialog extends StatefulWidget {
  final Category category;

  const EditCategoryDialog({
    Key? key,
    required this.category,
  }) : super(key: key);

  @override
  State<EditCategoryDialog> createState() => _EditCategoryDialogState();
}

class _EditCategoryDialogState extends State<EditCategoryDialog> {
  final TextEditingController _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final CategoryService _categoryService = CategoryService();
  
  // State จะเก็บ "ชื่อไอคอนภาษาอังกฤษ" เช่น 'water_drop'
  late String _selectedIcon;
  bool _isLoading = false;

  // ❌ ลบ Map และฟังก์ชันเกี่ยวกับไอคอนทั้งหมดจากที่นี่

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.category.name;
    // ✅ แปลง IconData ที่มีอยู่กลับเป็นชื่อภาษาอังกฤษ
    _selectedIcon = Category.getIconName(widget.category.icon);
  }

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
            // ✅ ใช้ availableIcons จาก model ที่ import เข้ามา
            itemCount: availableIcons.length,
            itemBuilder: (context, index) {
              final entry = availableIcons.entries.elementAt(index);
              final displayName = entry.key; // 'ค่าน้ำ'
              final iconData = entry.value; // Icons.water_drop
              // ✅ แปลง IconData เป็นชื่ออังกฤษสำหรับใช้เปรียบเทียบและบันทึก
              final iconKey = Category.getIconName(iconData); // 'water_drop'
              final isSelected = iconKey == _selectedIcon;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    // ✅ บันทึก "ชื่อภาษาอังกฤษ" ลงใน State
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
                        displayName, // ✅ แสดงผลเป็นภาษาไทย
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

  // lib/Screen/Pages/Category_manage/Widgets/Categoty/edit_category_dialog.dart

Future<void> _updateCategory() async {
  if (!_formKey.currentState!.validate()) return;
  
  setState(() => _isLoading = true);
  try {
    // ✅ แก้ไขการเรียกใช้ฟังก์ชันให้ถูกต้อง
    await _categoryService.updateCategory(
      widget.category.id,                 // พารามิเตอร์ตัวที่ 1 (categoryId)
      _nameController.text.trim(),        // พารามิเตอร์ตัวที่ 2 (newName)
      newIcon: _selectedIcon,             // พารามิเตอร์แบบระบุชื่อ (newIcon)
    );

    if (!mounted) return; // เช็คก่อนเรียกใช้ context
    Navigator.of(context).pop(); // ปิด dialog เมื่อสำเร็จ
    
    CoolAlert.show(
      context: context,
      type: CoolAlertType.success,
      title: 'สำเร็จ!',
      text: 'อัปเดตหมวดหมู่เรียบร้อยแล้ว',
      confirmBtnText: 'ตกลง',
      confirmBtnTextStyle: GoogleFonts.prompt(color: Colors.white),
    );
  } catch (e) {
    if (!mounted) return;
    CoolAlert.show(
      context: context,
      type: CoolAlertType.error,
      title: 'เกิดข้อผิดพลาด',
      text: e.toString(),
      confirmBtnText: 'ตกลง',
      confirmBtnTextStyle: GoogleFonts.prompt(color: Colors.white),
    );
  } finally {
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
}

  // ฟังก์ชันลบหมวดหมู่
  Future<void> _deleteCategory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.warning, color: Colors.red.shade600),
              const SizedBox(width: 8),
              Text(
                'ยืนยันการลบ',
                style: GoogleFonts.prompt(
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade600,
                ),
              ),
            ],
          ),
          content: Text(
            'คุณต้องการลบหมวดหมู่ "${widget.category.name}" ใช่หรือไม่?\n\nการกระทำนี้จะลบข้อมูลทั้งหมดที่เกี่ยวข้องและไม่สามารถย้อนกลับได้',
            style: GoogleFonts.prompt(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(
                'ยกเลิก',
                style: GoogleFonts.prompt(color: Colors.grey[600]),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
              ),
              child: Text(
                'ลบ',
                style: GoogleFonts.prompt(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      
      try {
        await _categoryService.deleteCategory(widget.category.id);
        
        if (context.mounted) {
          Navigator.of(context).pop(true); // ส่งสัญญาณว่าลบสำเร็จ
          
          CoolAlert.show(
            context: context,
            type: CoolAlertType.success,
            text: 'ลบหมวดหมู่ "${widget.category.name}" สำเร็จแล้ว!',
            confirmBtnText: 'ตกลง',
            backgroundColor: Colors.green.shade100,
            loopAnimation: false,
          );
        }
      } catch (e) {
        setState(() => _isLoading = false);
        
        if (context.mounted) {
          CoolAlert.show(
            context: context,
            type: CoolAlertType.error,
            title: 'เกิดข้อผิดพลาด',
            text: e.toString(),
            confirmBtnText: 'ปิด',
          );
        }
      }
    }
  }

@override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.category.isDefault ? 'ดูหมวดหมู่' : 'แก้ไขหมวดหมู่',
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
                enabled: !widget.category.isDefault,
                decoration: InputDecoration(
                  labelText: 'ชื่อหมวดหมู่',
                  prefixIcon: Icon(
                    // ✅ เรียกใช้ฟังก์ชันจาก Model โดยตรง
                    Category.getIconFromName(_selectedIcon),
                    color: widget.category.isDefault ? Colors.grey : Colors.blue,
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
              if (!widget.category.isDefault)
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
        // ปุ่มลบ (แสดงเฉพาะหมวดหมู่ของผู้ใช้)
        if (!widget.category.isDefault)
          TextButton.icon(
            onPressed: _isLoading ? null : _deleteCategory,
            icon: const Icon(Icons.delete),
            label: Text(
              'ลบ',
              style: GoogleFonts.prompt(),
            ),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red.shade600,
            ),
          ),
        
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: Text(
            'ยกเลิก',
            style: GoogleFonts.prompt(color: Colors.grey[600]),
          ),
        ),
        
        // ปุ่มบันทึก (แสดงเฉพาะหมวดหมู่ของผู้ใช้)
        if (!widget.category.isDefault)
          ElevatedButton(
            onPressed: _isLoading ? null : _updateCategory,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    'บันทึก',
                    style: GoogleFonts.prompt(fontWeight: FontWeight.w600),
                  ),
          ),
      ],
    );
  }
}