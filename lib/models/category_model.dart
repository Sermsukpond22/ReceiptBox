// lib/models/category_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// ✅ (เพิ่มเข้ามา) รวมศูนย์กลางข้อมูลไอคอนไว้ที่นี่ที่เดียว
final Map<String, IconData> availableIcons = {
  'ค่าน้ำ': Icons.water_drop,
  'ค่าไฟ': Icons.flash_on,
  'ค่าน้ำมัน': Icons.local_gas_station,
  'ร้านสะดวกซื้อ': Icons.store,
  'ซุปเปอร์มาเก็ต': Icons.shopping_cart,
  'อาหาร': Icons.restaurant,
  'เดินทาง': Icons.directions_car,
  'บันเทิง': Icons.movie,
  'การศึกษา': Icons.school,
  'สุขภาพ': Icons.medical_services,
  'บ้าน': Icons.home,
  'ทำงาน': Icons.work,
  'กีฬา': Icons.sports_soccer,
  'ชอปปิง': Icons.shopping_bag,
  'ท่องเที่ยว': Icons.flight,
  'สัตว์เลี้ยง': Icons.pets,
  'อื่นๆ': Icons.category,
};

class Category {
  final String id;
  final String name;
  final IconData icon; // ✅ ใช้ IconData โดยตรงในโมเดล
  final String? userId;
  final Timestamp createdAt;
  final Timestamp? updatedAt;

  Category({
    required this.id,
    required this.name,
    required this.icon,
    this.userId,
    required this.createdAt,
    this.updatedAt,
  });

  // ✅ ใช้ Getter ในการเช็คว่าเป็นหมวดหมู่พื้นฐานหรือไม่ (ดีกว่าเก็บเป็น field)
  bool get isDefault => userId == null;

  /// ✅ (เพิ่ม) แปลงชื่อ icon (String) จาก Firestore → เป็น IconData
  static IconData getIconFromName(String? iconName) {
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

  /// ✅ (เพิ่ม) แปลง IconData → เป็นชื่อ (String) สำหรับบันทึกลง Firestore
  static String getIconName(IconData? iconData) {
    final reversedMap = {
      Icons.water_drop: 'water_drop',
      Icons.flash_on: 'flash_on',
      Icons.local_gas_station: 'local_gas_station',
      Icons.store: 'store',
      Icons.shopping_cart: 'shopping_cart',
      Icons.restaurant: 'restaurant',
      Icons.directions_car: 'directions_car',
      Icons.movie: 'movie',
      Icons.school: 'school',
      Icons.medical_services: 'medical_services',
      Icons.home: 'home',
      Icons.work: 'work',
      Icons.sports_soccer: 'sports_soccer',
      Icons.shopping_bag: 'shopping_bag',
      Icons.flight: 'flight',
      Icons.pets: 'pets',
      Icons.category: 'category',
    };
    return reversedMap[iconData] ?? 'category';
  }

  /// ✅ (แก้ไข) Factory constructor ที่ Service เรียกใช้
  /// ทำให้รองรับการแปลงค่า 'icon' ที่เป็น String จาก Firestore ได้
  factory Category.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Category(
      id: doc.id,
      name: data['name'] ?? '',
      // ✅ แปลง 'icon' (String) ที่อ่านได้ มาเป็น IconData
      icon: getIconFromName(data['icon']),
      userId: data['userId'],
      createdAt: (data['createdAt'] as Timestamp?) ?? Timestamp.now(),
      updatedAt: data['updatedAt'] as Timestamp?,
    );
  }

  /// ✅ (แก้ไข) แปลง Category object กลับเป็น Map เพื่อบันทึกลง Firestore
  /// โดยจะบันทึก 'icon' เป็น String ซึ่งตรงกับที่ Service ต้องการ
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'createdAt': createdAt,
      'userId': userId,
      'updatedAt': updatedAt,
      // ✅ แปลง IconData กลับไปเป็น String ชื่อ 'icon' เพื่อบันทึก
      'icon': getIconName(icon),
    };
  }
}