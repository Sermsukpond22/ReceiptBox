// lib/Screen/Pages/Category_manage/Widgets/add_category_dialog.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:run_android/Screen/Pages/Category_manage/Widgets/Categoty/category_models.dart';


class AddCategoryDialog extends StatefulWidget {
  const AddCategoryDialog({super.key});

  @override
  State<AddCategoryDialog> createState() => _AddCategoryDialogState();
}

class _AddCategoryDialogState extends State<AddCategoryDialog> {
  final TextEditingController _categoryNameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _selectedIcon = 'category'; // Default icon

  @override
  void dispose() {
    _categoryNameController.dispose();
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
              final isSelected = _getIconNameFromIconData(iconData) == _selectedIcon;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedIcon = _getIconNameFromIconData(iconData);
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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Text(
        'เพิ่มหมวดหมู่ใหม่',
        style: GoogleFonts.prompt(
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ช่องกรอกชื่อหมวดหมู่
              TextFormField(
                controller: _categoryNameController,
                decoration: InputDecoration(
                  labelText: 'ชื่อหมวดหมู่',
                  hintText: 'เช่น อาหาร, ค่าเดินทาง, บันเทิง',
                  prefixIcon: Icon(
                    _getIconDataFromName(_selectedIcon),
                    color: Colors.blue,
                  ),
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
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(); // ปิด Dialog โดยไม่ส่งค่ากลับ
          },
          child: Text(
            'ยกเลิก',
            style: GoogleFonts.prompt(color: Colors.grey[600]),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              // ส่งข้อมูลหมวดหมู่กลับไป (ชื่อและไอคอน)
              Navigator.of(context).pop({
                'name': _categoryNameController.text.trim(),
                'icon': _selectedIcon,
              });
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue.shade600,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          child: Text(
            'เพิ่ม',
            style: GoogleFonts.prompt(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}