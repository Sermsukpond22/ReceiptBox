import 'package:flutter/material.dart';
import 'package:run_android/Screen/Pages/%E0%B9%87HomePage/category_transactions_page.dart';

class CategoriesGridWidget extends StatelessWidget {
  final List<Map<String, dynamic>> categories;

  const CategoriesGridWidget({super.key, required this.categories});

  IconData _getIconData(String? iconName) {
    // ฟังก์ชันนี้เหมือนเดิม แต่ยกมาไว้ใน Widget ของตัวเอง
    // (สามารถสร้างเป็นไฟล์ utility แยกต่างหากได้ถ้าใช้ในหลายที่)
    switch (iconName) {
      case 'restaurant_menu':
        return Icons.restaurant_menu;
      case 'shopping_cart':
        return Icons.shopping_cart;
      case 'fastfood':
        return Icons.fastfood;
      // ... (เพิ่ม case อื่นๆ ทั้งหมดที่นี่)
      default:
        return Icons.category;
    }
  }

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
          const Text(
            'หมวดหมู่',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
              final category = categories[index];
              final categoryName = category['name'] as String? ?? 'ไม่ระบุ';
              // ✨ ดึง categoryId จาก map
              final categoryId = category['id'] as String? ?? '';
              final categoryIcon =
                  _getIconData(category['iconName'] as String?);

              // ตรวจสอบว่า categoryId ไม่ใช่ค่าว่าง
              if (categoryId.isEmpty) {
                // อาจจะแสดงเป็น widget ที่กดไม่ได้ หรือซ่อนไปเลย
                return const SizedBox.shrink();
              }

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CategoryTransactionsPage(
                        // ✨ ส่งทั้ง categoryId และ categoryName ไปด้วย
                        categoryId: categoryId,
                        categoryName: categoryName,
                      ),
                    ),
                  );
                },
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.blue.withOpacity(0.1),
                      child: Icon(categoryIcon, color: Colors.blue),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      categoryName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12),
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
