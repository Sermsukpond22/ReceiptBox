import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:run_android/models/category_model.dart'; // ตรวจสอบให้แน่ใจว่า import ถูกต้อง

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
                    // ✅ เปลี่ยนจาก Icons.settings / Icons.label
                    // มาใช้ category.icon โดยมี fallback เป็น Icons.category
                    category.icon ?? Icons.category, // ใช้ไอคอนจาก category model, ถ้าไม่มีให้ใช้ Icons.category เป็นค่าเริ่มต้น
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
                        // ตรวจสอบว่า createdAt ไม่เป็น null ก่อน format
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
}
