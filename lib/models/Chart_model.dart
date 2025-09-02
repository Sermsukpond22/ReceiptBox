// ตรวจสอบว่ามี Class นี้อยู่ (อาจจะอยู่ใน HomePage.dart หรือไฟล์แยก)
import 'dart:ui';

class CategoryExpense {
  final String name;
  final double amount;
  final Color color;

  CategoryExpense(this.name, this.amount, this.color);
}