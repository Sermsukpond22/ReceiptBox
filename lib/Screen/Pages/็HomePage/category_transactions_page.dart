import 'package:flutter/material.dart';
import 'package:run_android/Screen/Pages/Category_manage/Widgets/Receipt/receipt_list_page.dart';



class CategoryTransactionsPage extends StatelessWidget {
  // ✨ 2. เพิ่มพารามิเตอร์สำหรับรับ categoryId
  final String categoryId;
  final String categoryName;

  const CategoryTransactionsPage({
    super.key,
    required this.categoryId, // ทำให้ต้องรับค่านี้เสมอ
    required this.categoryName,
  });

  @override
  Widget build(BuildContext context) {
    // ✨ 3. ไม่ต้องสร้าง Scaffold ใหม่ เพราะ ReceiptList มี Scaffold ของตัวเองอยู่แล้ว
    //    เราเพียงแค่ส่งค่าที่จำเป็น (categoryId, categoryName) ไปให้มันก็พอ
    return ReceiptList(
      categoryId: categoryId,
      categoryName: categoryName,
    );
  }
}