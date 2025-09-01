import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Category {
  final String id;
  final String name;
  final IconData icon;
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

  /// เป็นหมวดหมู่พื้นฐาน (ไม่มี userId)
  bool get isDefault => userId == null;

  /// เป็นหมวดหมู่ของผู้ใช้ (มี userId)
  bool get isUserCategory => userId != null;

  /// แปลงชื่อ icon (String) → IconData
  static IconData _getIconFromName(String? iconName) {
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
      default: return Icons.category; // fallback
    }
  }

  /// แปลง IconData → ชื่อ icon (String)
  static String _getIconName(IconData? iconData) {
    if (iconData == null) return 'category';

    final mapping = {
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

    return mapping[iconData] ?? 'category';
  }

  /// สร้าง Category object จาก Firestore document
  factory Category.fromFirestore(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Category(
      id: doc.id,
      name: data['name'] ?? 'ไม่ระบุชื่อ',
      icon: _getIconFromName(data['icon']),
      userId: data['userId'],
      createdAt: data['createdAt'] ?? Timestamp.now(),
      // รองรับทั้ง updatedAt และ updateAt (กัน error เก่า)
      updatedAt: data['updatedAt'] ?? data['updateAt'],
    );
  }

  /// จาก DocumentSnapshot (กรณี getCategoryById)
  factory Category.fromDocumentSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;

    if (data == null) {
      throw Exception('ข้อมูลหมวดหมู่ไม่ถูกต้อง');
    }

    return Category(
      id: doc.id,
      name: data['name'] ?? 'ไม่ระบุชื่อ',
      icon: _getIconFromName(data['icon']),
      userId: data['userId'],
      createdAt: data['createdAt'] ?? Timestamp.now(),
      updatedAt: data['updatedAt'] ?? data['updateAt'],
    );
  }

  /// แปลง Category → Map (สำหรับบันทึก Firestore)
  Map<String, dynamic> toMap({bool includeId = false}) {
    final map = <String, dynamic>{
      'name': name,
      'icon': _getIconName(icon),
      'userId': userId,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };

    if (includeId) {
      map['id'] = id;
    }

    return map;
  }

  /// copy object
  Category copyWith({
    String? id,
    String? name,
    IconData? icon,
    String? userId,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() =>
      'Category(id: $id, name: $name, icon: ${_getIconName(icon)}, userId: $userId, isDefault: $isDefault)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Category &&
          other.id == id &&
          other.name == name &&
          other.icon == icon &&
          other.userId == userId;

  @override
  int get hashCode =>
      id.hashCode ^ name.hashCode ^ icon.hashCode ^ userId.hashCode;
}

/// icon ที่พร้อมให้เลือกใช้
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
