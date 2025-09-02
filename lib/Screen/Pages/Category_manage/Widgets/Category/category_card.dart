// lib/Screen/Pages/Category_manage/Widgets/Categoty/category_card.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:run_android/models/category_model.dart';

class CategoryCard extends StatelessWidget {
  final Category category;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const CategoryCard({
    Key? key,
    required this.category,
    this.onTap,
    this.onLongPress,
    this.onEdit,
    this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // ไอคอนหมวดหมู่
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: category.isDefault
                        ? Colors.orange.shade50
                        : Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: category.isDefault
                          ? Colors.orange.shade200
                          : Colors.blue.shade200,
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    category.icon ?? Icons.category,
                    color: category.isDefault
                        ? Colors.orange.shade600
                        : Colors.blue.shade600,
                    size: 24,
                  ),
                ),

                const SizedBox(width: 16),

                // ข้อมูลหมวดหมู่
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              category.name,
                              style: GoogleFonts.prompt(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          if (category.isDefault)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'พื้นฐาน',
                                style: GoogleFonts.prompt(
                                  fontSize: 10,
                                  color: Colors.orange.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatDate(category.createdAt.toDate()),
                            style: GoogleFonts.prompt(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),

                          // แสดงวันที่แก้ไข (ถ้ามี)
                          // if (category.updatedAt != null) ...[
                          //   const SizedBox(width: 8),
                          //   Icon(
                          //     Icons.edit,
                          //     size: 14,
                          //     color: Colors.grey.shade500,
                          //   ),
                          //   const SizedBox(width: 4),
                          //   Text(
                          //     'แก้ไข ${_formatDate(category.updatedAt?.toDate())}',
                          //     style: GoogleFonts.prompt(
                          //       fontSize: 12,
                          //       color: Colors.grey.shade600,
                          //     ),
                          //   ),
                          // ],
                        ],
                      ),
                    ],
                  ),
                ),

                // ปุ่มจัดการ (เฉพาะหมวดหมู่ของผู้ใช้)
                if (!category.isDefault) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: onLongPress ?? onEdit,
                    icon: const Icon(Icons.more_vert),
                    color: Colors.grey.shade600,
                    tooltip: 'แก้ไขหมวดหมู่',
                  ),
                ],

                // ลูกศรไปยังรายละเอียด
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey.shade400,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// ✅ ฟังก์ชันแปลงวันที่ให้อ่านง่าย
  String _formatDate(DateTime? date) {
    if (date == null) return 'ไม่ระบุ';

    try {
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        return 'วันนี้';
      } else if (difference.inDays == 1) {
        return 'เมื่อวาน';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} วันที่แล้ว';
      } else if (difference.inDays < 30) {
        final weeks = (difference.inDays / 7).floor();
        return '$weeks สัปดาห์ที่แล้ว';
      } else if (difference.inDays < 365) {
        final months = (difference.inDays / 30).floor();
        return '$months เดือนที่แล้ว';
      } else {
        final years = (difference.inDays / 365).floor();
        return '$years ปีที่แล้ว';
      }
    } catch (e) {
      return 'ไม่ระบุ';
    }
  }
}
