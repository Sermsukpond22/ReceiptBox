import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart'; // สำคัญมากที่ต้อง import 'package:flutter/material.dart';

class Category {
  final String id;
  final String name;
  final Timestamp createdAt;
  final bool isDefault;
  final IconData? icon; // Field to store IconData

  Category({
    required this.id,
    required this.name,
    required this.createdAt,
    this.isDefault = false,
    this.icon, // Allow icon to be passed in constructor
  });

  // Factory constructor for creating a Category from a Firestore DocumentSnapshot
  factory Category.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Category(
      id: doc.id,
      name: data['name'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?) ?? Timestamp.now(),
      isDefault: data['userId'] == null, // Default categories have userId = null
      icon: data['iconCodePoint'] != null // Convert iconCodePoint to IconData
          ? IconData(
              int.parse(data['iconCodePoint'].toString()), // Ensure it's parsed as int
              fontFamily: 'MaterialIcons', // Specify the font family
            )
          : null,
    );
  }

  // Convert Category object to a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'createdAt': createdAt,
      'userId': isDefault ? null : FirebaseAuth.instance.currentUser?.uid, // Handle userId for default vs user categories
      'isDefault': isDefault,
      'iconCodePoint': icon?.codePoint.toString(), // Store codePoint as String
      'updatedAt': FieldValue.serverTimestamp(), // Add or update updatedAt
    };
  }
}