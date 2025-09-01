import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:run_android/Screen/Pages/Category_manage/Widgets/Categoty/category_card.dart';
import 'package:run_android/Screen/Pages/Category_manage/Widgets/Receipt/all_receipt_page.dart';
import 'package:run_android/Screen/Pages/Category_manage/Widgets/Receipt/receipt_list_page.dart';
import 'package:run_android/models/category_model.dart';


class CategoryListView extends StatelessWidget {
  final List<Category> categories;
  final String searchQuery;

  const CategoryListView({
    Key? key,
    required this.categories,
    required this.searchQuery,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // ✨ 2. ตรวจสอบว่าควรแสดง AllReceiptsCard หรือไม่ (เมื่อไม่มีการค้นหา)
    final bool showAllReceiptsCard = searchQuery.isEmpty;

    if (categories.isEmpty && searchQuery.isNotEmpty) {
      // แสดงสถานะว่างเมื่อค้นหาแล้วไม่เจอเท่านั้น
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 20),
      // ✨ 3. กำหนด itemCount แบบไดนามิก
      // ถ้าแสดง AllReceiptsCard ให้บวกจำนวนเพิ่ม 1
      itemCount: showAllReceiptsCard ? categories.length + 1 : categories.length,
      itemBuilder: (context, index) {
        // ✨ 4. เงื่อนไขในการแสดง Widget
        if (showAllReceiptsCard && index == 0) {
          //ถ้ารายการแรกและไม่มีการค้นหา ให้แสดง AllReceiptsCard
          return const AllReceiptsPage();
        }

        // คำนวณ index ของ category list ให้ถูกต้อง
        // ถ้าแสดง AllReceiptsCard อยู่ ให้ลบ index ออก 1
        final categoryIndex = showAllReceiptsCard ? index - 1 : index;
        final category = categories[categoryIndex];

        // แสดง CategoryCard ปกติ
        return CategoryCard(
          category: category,
          // ✨ 5. เพิ่ม onTap เพื่อนำทางไปยังหน้ารายละเอียดของแต่ละหมวดหมู่
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ReceiptList(
                  categoryId: category.id,
                  categoryName: category.name,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.search_off, size: 60, color: Colors.grey[400]),
          ),
          const SizedBox(height: 24),
          Text(
            'ไม่พบหมวดหมู่ที่ค้นหา',
            style: GoogleFonts.prompt(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'ลองใช้คำค้นหาอื่น',
            style: GoogleFonts.prompt(fontSize: 16, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
