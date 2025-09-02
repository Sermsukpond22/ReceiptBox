import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// ✅ 1. Import โมเดล Category เข้ามา
import 'package:run_android/models/category_model.dart'; 
import 'package:run_android/Screen/Pages/HomePage/category_transactions_page.dart';

class CategoriesGridWidget extends StatelessWidget {
  // ✅ 2. เปลี่ยนประเภทของ categories ให้เป็น List<Category>
  final List<Category> categories;

  const CategoriesGridWidget({super.key, required this.categories});

  // ❌ 3. ลบฟังก์ชัน _getIconData ที่ซ้ำซ้อนออกทั้งหมด

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(child: Text('กำลังโหลดหมวดหมู่...')),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'หมวดหมู่',
            style: GoogleFonts.prompt(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.8,
            ),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              // ✅ 4. ตอนนี้ 'category' เป็น Object ของ Class Category แล้ว
              final category = categories[index];

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CategoryTransactionsPage(
                        // ✅ 5. เรียกใช้ property จาก object ได้โดยตรง
                        categoryId: category.id,
                        categoryName: category.name,
                      ),
                    ),
                  );
                },
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.blue.withOpacity(0.1),
                      // ✅ 6. ใช้ category.icon ได้เลย เพราะเป็น IconData อยู่แล้ว
                      child: Icon(category.icon, color: Colors.blue),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      category.name, // ✅ เรียกใช้ property ได้โดยตรง
                      textAlign: TextAlign.center,
                      style: GoogleFonts.prompt(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}