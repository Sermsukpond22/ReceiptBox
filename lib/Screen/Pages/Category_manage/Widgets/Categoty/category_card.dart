import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:run_android/Screen/Pages/Category_manage/Widgets/Categoty/edit_category_dialog.dart';
import 'package:run_android/models/category_model.dart';


class CategoryCard extends StatelessWidget {
  final Category category;
  final VoidCallback? onTap;

  const CategoryCard({
    Key? key,
    required this.category,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final thaiDateFormat = DateFormat('d MMM yyyy', 'th_TH');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          // เพิ่ม onLongPress สำหรับการแสดงเมนูแก้ไข/ลบ
          onLongPress: category.isDefault ? null : () => _showCategoryOptions(context),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: category.isDefault
                        ? Colors.grey[200]
                        : Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    category.icon ?? Icons.category,
                    size: 28,
                    color: category.isDefault
                        ? Colors.grey[600]
                        : Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.name,
                        style: GoogleFonts.prompt(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[850],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'สร้างเมื่อ: ${category.createdAt.toDate() != null ? thaiDateFormat.format(category.createdAt.toDate()) : 'N/A'}',
                        style: GoogleFonts.prompt(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[500]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // เมธอดสำหรับแสดง bottom sheet เพื่อให้ผู้ใช้เลือกการกระทำ
  void _showCategoryOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              // ปุ่มแก้ไข
              ListTile(
                leading: Icon(Icons.edit, color: Colors.blue[600]),
                title: Text(
                  'แก้ไขหมวดหมู่',
                  style: GoogleFonts.prompt(fontSize: 16),
                ),
                onTap: () {
                  Navigator.of(context).pop(); // ปิด bottom sheet
                  // 🔥 เรียกใช้ dialog แก้ไข/ลบ
                  showDialog(
                    context: context,
                    builder: (BuildContext dialogContext) {
                      return CategoryManagementDialog(category: category);
                    },
                  );
                },
              ),
              // ปุ่มลบ
              ListTile(
                leading: Icon(Icons.delete_forever, color: Colors.red[600]),
                title: Text(
                  'ลบหมวดหมู่',
                  style: GoogleFonts.prompt(fontSize: 16),
                ),
                onTap: () {
                  Navigator.of(context).pop(); // ปิด bottom sheet
                  // 🔥 เรียกใช้ dialog แก้ไข/ลบ
                  showDialog(
                    context: context,
                    builder: (BuildContext dialogContext) {
                      return CategoryManagementDialog(category: category);
                    },
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
