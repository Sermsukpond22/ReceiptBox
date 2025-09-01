// lib/Screen/Pages/Category_manage/Widgets/edit_category_dialog.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:run_android/models/category_model.dart';
import 'package:run_android/services/categories_service.dart';
import 'package:cool_alert/cool_alert.dart';

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
  
  String _selectedIcon = 'category';
  bool _isLoading = false;

  // รายการไอคอนที่สามารถใช้ได้
  final Map<String, IconData> availableIcons = {
    'หยดน้ำ': Icons.water_drop,
    'ไฟฟ้า': Icons.flash_on,
    'ปั๊มน้ำมัน': Icons.local_gas_station,
    'ร้านค้า': Icons.store,
    'รถเข็น': Icons.shopping_cart,
    'ร้านอาหาร': Icons.restaurant,
    'รถยนต์': Icons.directions_car,
    'ภาพยนตร์': Icons.movie,
    'โรงเรียน': Icons.school,
    'การแพทย์': Icons.medical_services,
    'บ้าน': Icons.home,
    'งาน': Icons.work,
    'ฟุตบอล': Icons.sports_soccer,
    'ถุงช้อปปิ้ง': Icons.shopping_bag,
    'เครื่องบิน': Icons.flight,
    'สัตว์เลี้ยง': Icons.pets,
    'หมวดหมู่': Icons.category,
  };

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.category.name;
    _selectedIcon = _getIconNameFromIconData(widget.category.icon ?? Icons.category);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // ฟังก์ชันแสดง Dialog เลือกไอคอน
  void _showIconPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'เลือกไอคอน',
          style: GoogleFonts.prompt(fontWeight: FontWeight.bold),
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: availableIcons.length,
            itemBuilder: (context, index) {
              final entry = availableIcons.entries.elementAt(index);
              final iconName = entry.key;
              final iconData = entry.value;
              final iconKey = _getIconNameFromIconData(iconData);
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
                    color: isSelected ? Colors.blue.shade100 : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? Colors.blue : Colors.grey.shade300,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        iconData,
                        size: 24,
                        color: isSelected ? Colors.blue : Colors.grey.shade700,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        iconName,
                        style: GoogleFonts.prompt(
                          fontSize: 10,
                          color: isSelected ? Colors.blue : Colors.grey.shade600,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
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
            child: Text(
              'ปิด',
              style: GoogleFonts.prompt(color: Colors.grey[600]),
            ),
          ),
        ],
      ),
    );
  }

  // ฟังก์ชันแปลง IconData เป็นชื่อไอคอน
  String _getIconNameFromIconData(IconData iconData) {
    if (iconData == Icons.water_drop) return 'water_drop';
    if (iconData == Icons.flash_on) return 'flash_on';
    if (iconData == Icons.local_gas_station) return 'local_gas_station';
    if (iconData == Icons.store) return 'store';
    if (iconData == Icons.shopping_cart) return 'shopping_cart';
    if (iconData == Icons.restaurant) return 'restaurant';
    if (iconData == Icons.directions_car) return 'directions_car';
    if (iconData == Icons.movie) return 'movie';
    if (iconData == Icons.school) return 'school';
    if (iconData == Icons.medical_services) return 'medical_services';
    if (iconData == Icons.home) return 'home';
    if (iconData == Icons.work) return 'work';
    if (iconData == Icons.sports_soccer) return 'sports_soccer';
    if (iconData == Icons.shopping_bag) return 'shopping_bag';
    if (iconData == Icons.flight) return 'flight';
    if (iconData == Icons.pets) return 'pets';
    return 'category';
  }

  // ฟังก์ชันแปลงชื่อไอคอนเป็น IconData
  IconData _getIconDataFromName(String iconName) {
    switch (iconName) {
      case 'water_drop': return Icons.water_drop;
      case 'flash_on': return Icons.flash_on;
      case 'local_gas_station': return Icons.local_gas_station;
      case 'store': return Icons.store;
      case 'shopping_cart': return Icons.shopping_cart;
      case 'restaurant': return Icons.restaurant;
      case 'directions_car': return Icons.directions_car;
      case 'movie': return Icons.movie;
      case 'school': return Icons.school;
      case 'medical_services': return Icons.medical_services;
      case 'home': return Icons.home;
      case 'work': return Icons.work;
      case 'sports_soccer': return Icons.sports_soccer;
      case 'shopping_bag': return Icons.shopping_bag;
      case 'flight': return Icons.flight;
      case 'pets': return Icons.pets;
      default: return Icons.category;
    }
  }

  // ฟังก์ชันอัปเดตหมวดหมู่
  Future<void> _updateCategory() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      await _categoryService.updateCategory(
        widget.category.id,
        _nameController.text.trim(),
        newIcon: _selectedIcon,
      );

      if (context.mounted) {
        Navigator.of(context).pop(true); // ส่งสัญญาณว่าอัปเดตสำเร็จ
        
        CoolAlert.show(
          context: context,
          type: CoolAlertType.success,
          text: 'แก้ไขหมวดหมู่ "${_nameController.text.trim()}" สำเร็จแล้ว!',
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          Icon(
            widget.category.icon ?? Icons.category,
            color: Colors.blue.shade600,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'แก้ไขหมวดหมู่',
              style: GoogleFonts.prompt(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // แสดงสถานะหมวดหมู่
              if (widget.category.isDefault)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info, color: Colors.orange.shade600, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'หมวดหมู่พื้นฐาน - ไม่สามารถแก้ไขหรือลบได้',
                          style: GoogleFonts.prompt(
                            color: Colors.orange.shade700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // ช่องกรอกชื่อหมวดหมู่
              TextFormField(
                controller: _nameController,
                enabled: !widget.category.isDefault,
                decoration: InputDecoration(
                  labelText: 'ชื่อหมวดหมู่',
                  prefixIcon: Icon(
                    _getIconDataFromName(_selectedIcon),
                    color: widget.category.isDefault ? Colors.grey : Colors.blue,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: widget.category.isDefault ? Colors.grey[100] : Colors.grey[50],
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
              
              if (!widget.category.isDefault) ...[
                const SizedBox(height: 16),
                
                // ปุ่มเลือกไอคอน
                Text(
                  'เลือกไอคอน',
                  style: GoogleFonts.prompt(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _showIconPicker,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.grey.shade50,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _getIconDataFromName(_selectedIcon),
                          color: Colors.blue,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'เลือกไอคอนสำหรับหมวดหมู่',
                          style: GoogleFonts.prompt(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: Colors.grey[400],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
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