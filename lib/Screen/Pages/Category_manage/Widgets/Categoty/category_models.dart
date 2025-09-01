// lib/models/category_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Category {
  final String id;
  final String name;
  final IconData? icon;
  final String? userId;
  final Timestamp createdAt;
  final Timestamp? updatedAt;

  Category({
    required this.id,
    required this.name,
    this.icon,
    this.userId,
    required this.createdAt,
    this.updatedAt,
  });

  // ตรวจสอบว่าเป็นหมวดหมู่พื้นฐานหรือไม่
  bool get isDefault => userId == null;

  // ตรวจสอบว่าเป็นหมวดหมู่ของผู้ใช้หรือไม่
  bool get isUserCategory => userId != null;

  // แปลงชื่อไอคอนเป็น IconData
  static IconData? _getIconFromName(String? iconName) {
    if (iconName == null) return Icons.category;
    
    switch (iconName) {
      case 'water_drop':
        return Icons.water_drop;
      case 'flash_on':
        return Icons.flash_on;
      case 'local_gas_station':
        return Icons.local_gas_station;
      case 'store':
        return Icons.store;
      case 'shopping_cart':
        return Icons.shopping_cart;
      case 'restaurant':
        return Icons.restaurant;
      case 'directions_car':
        return Icons.directions_car;
      case 'movie':
        return Icons.movie;
      case 'school':
        return Icons.school;
      case 'medical_services':
        return Icons.medical_services;
      case 'home':
        return Icons.home;
      case 'work':
        return Icons.work;
      case 'sports_soccer':
        return Icons.sports_soccer;
      case 'shopping_bag':
        return Icons.shopping_bag;
      case 'flight':
        return Icons.flight;
      case 'pets':
        return Icons.pets;
      case 'category':
      case 'default':
        return Icons.category;
      default:
        return Icons.category; // fallback icon
    }
  }

  // สร้าง Category object จาก Firestore document
  factory Category.fromFirestore(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return Category(
      id: doc.id,
      name: data['name'] ?? 'ไม่ระบุชื่อ',
      icon: _getIconFromName(data['icon']),
      userId: data['userId'],
      createdAt: data['createdAt'] ?? Timestamp.now(),
      updatedAt: data['updatedAt'],
    );
  }

  // สร้าง Category object จาก DocumentSnapshot (สำหรับ getCategoryById)
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
      updatedAt: data['updatedAt'],
    );
  }

  // แปลง Category object เป็น Map สำหรับบันทึกใน Firestore
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

  // แปลง IconData เป็นชื่อไอคอน
  static String _getIconName(IconData? iconData) {
    if (iconData == null) return 'category';
    
    if (iconData == Icons.water_drop) return 'water_drop';
    if (iconData == Icons.flash_on) return 'flash_on';
    if (iconData == Icons.local_gas_station) return 'local_gas_station';
    if (iconData == Icons.store) return 'store';
    if (iconData == Icons.shopping_cart) return 'shopping_cart';
    if (iconData == Icons.restaurant) return 'restaurant';
    if (iconData == Icons.directions_car) return 'directions_car';
    if (iconData == Icons.movie) return 'movie';
    if (iconData == Icons.school) return 'school';
    if (iconData == Icons.medical_services) return 'medical_services';
    if (iconData == Icons.home) return 'home';
    if (iconData == Icons.work) return 'work';
    if (iconData == Icons.sports_soccer) return 'sports_soccer';
    if (iconData == Icons.shopping_bag) return 'shopping_bag';
    if (iconData == Icons.flight) return 'flight';
    if (iconData == Icons.pets) return 'pets';
    
    return 'category'; // default
  }

  // สร้าง copy ของ Category object พร้อมการแก้ไขค่าบางอย่าง
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
  String toString() {
    return 'Category(id: $id, name: $name, icon: ${_getIconName(icon)}, userId: $userId, isDefault: $isDefault)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is Category &&
        other.id == id &&
        other.name == name &&
        other.icon == icon &&
        other.userId == userId;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        icon.hashCode ^
        userId.hashCode;
  }
}