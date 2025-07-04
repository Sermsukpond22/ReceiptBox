import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Model for category data
class Category {
  final String id;
  final String name;
  final String? userId; // null = default
  final Timestamp createdAt;
  final Timestamp? updatedAt;

  Category({
    required this.id,
    required this.name,
    required this.userId,
    required this.createdAt,
    this.updatedAt,
  });

  factory Category.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Category(
      id: doc.id,
      name: data['name'] as String,
      userId: data['userId'] as String?,
      createdAt: data['createdAt'] as Timestamp,
      updatedAt: data['updatedAt'] as Timestamp?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'userId': userId,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}

/// Service for managing categories
class CategoryService {
  static final CategoryService _instance = CategoryService._internal();
  factory CategoryService() => _instance;
  CategoryService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;
  bool get isUserLoggedIn => currentUser != null;

  /// ✅ Creates a new custom category for the current user
  Future<String> createCategory(String name) async {
    try {
      final user = currentUser;
      if (user == null) throw Exception('กรุณาเข้าสู่ระบบก่อนใช้งาน');

      final docRef = await _firestore.collection('categories').add({
        'name': name.trim(),
        'userId': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': null,
      });
      return docRef.id;
    } catch (e) {
      throw Exception('สร้างหมวดหมู่ไม่สำเร็จ: $e');
    }
  }

  /// ✅ Fetches only user-specific categories
  Stream<List<Category>> getUserCategories() {
    final user = currentUser;
    if (user == null) throw Exception('กรุณาเข้าสู่ระบบก่อนใช้งาน');

    return _firestore
        .collection('categories')
        .where('userId', isEqualTo: user.uid)
        .orderBy('name')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Category.fromFirestore(doc)).toList());
  }

  /// ✅ Fetches both default and user-specific categories
  Stream<List<Category>> getAllCategoriesForUser() async* {
  final user = currentUser;
  if (user == null) throw Exception('กรุณาเข้าสู่ระบบก่อนใช้งาน');

  final defaultQuery = _firestore
      .collection('categories')
      .where('userId', isNull: true)
      .orderBy('name')
      .snapshots();

  final userQuery = _firestore
      .collection('categories')
      .where('userId', isEqualTo: user.uid)
      .orderBy('name')
      .snapshots();

  await for (final defaultSnap in defaultQuery) {
    final defaultCategories = defaultSnap.docs.map((doc) => Category.fromFirestore(doc)).toList();

    await for (final userSnap in userQuery) {
      final userCategories = userSnap.docs.map((doc) => Category.fromFirestore(doc)).toList();

      yield [...defaultCategories, ...userCategories];
      break; // yield one combined result only
    }
  }
}


  /// ✅ Updates a custom category (not allowed for default)
  Future<void> updateCategory(String categoryId, String newName) async {
    final user = currentUser;
    if (user == null) throw Exception('กรุณาเข้าสู่ระบบก่อนใช้งาน');

    final doc = await _firestore.collection('categories').doc(categoryId).get();
    if (doc.exists) {
      final data = doc.data()!;
      if (data['userId'] == null) {
        throw Exception('ไม่สามารถแก้ไขหมวดหมู่พื้นฐานได้');
      }
    }

    await _firestore.collection('categories').doc(categoryId).update({
      'name': newName.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// ✅ Deletes a custom category (not allowed for default)
  Future<void> deleteCategory(String categoryId) async {
    final user = currentUser;
    if (user == null) throw Exception('กรุณาเข้าสู่ระบบก่อนใช้งาน');

    final doc = await _firestore.collection('categories').doc(categoryId).get();
    if (doc.exists) {
      final data = doc.data()!;
      if (data['userId'] == null) {
        throw Exception('ไม่สามารถลบหมวดหมู่พื้นฐานได้');
      }
    }

    await _firestore.collection('categories').doc(categoryId).delete();
  }

  /// ✅ Fetches a single category by its ID
  Future<Category?> getCategoryById(String categoryId) async {
    try {
      final doc =
          await _firestore.collection('categories').doc(categoryId).get();
      if (doc.exists) {
        return Category.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('ดึงข้อมูลหมวดหมู่ไม่สำเร็จ: $e');
    }
  }

  /// ✅ Batch create default categories (run once for system)
  Future<void> createDefaultCategoriesIfNotExists() async {
    final defaultNames = [
      'ค่าน้ำ',
      'ค่าไฟ',
      'ค่าน้ำมัน',
      'ใบเสร็จร้านสะดวกซื้อ',
      'ใบเสร็จซุปเปอร์มาเก็ต'
    ];

    for (final name in defaultNames) {
      final query = await _firestore
          .collection('categories')
          .where('name', isEqualTo: name)
          .where('userId', isNull: true)
          .get();

      if (query.docs.isEmpty) {
        await _firestore.collection('categories').add({
          'name': name,
          'userId': null,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': null,
        });
      }
    }
  }
}
