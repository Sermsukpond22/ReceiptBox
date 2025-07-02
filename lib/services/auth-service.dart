import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  /// อัปโหลดรูปภาพโปรไฟล์ไปยัง Firebase Storage
  static Future<String> uploadProfileImage(File imageFile, String uid) async {
    try {
      final ref = _storage.ref().child('profile_images').child('$uid.jpg');
      final uploadTask = await ref.putFile(imageFile);
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('อัปโหลดรูปภาพล้มเหลว: $e');
    }
  }

  /// ลงทะเบียนผู้ใช้ใหม่และอัปโหลดรูปภาพ
  static Future<void> registerUser({
    required String email,
    required String password,
    required String fullName,
    required String phoneNumber,
    required File profileImageFile, // เปลี่ยนจาก URL เป็นไฟล์รูป
  }) async {
    try {
      // สร้างบัญชีผู้ใช้ใน Firebase Auth
      final UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final String uid = userCredential.user!.uid;
      final String userID = const Uuid().v4();

      // อัปโหลดรูปภาพและรับ URL กลับมา
      final String imageUrl = await uploadProfileImage(profileImageFile, uid);

      // เตรียมข้อมูลผู้ใช้เพื่อบันทึกใน Firestore
      final Map<String, dynamic> userData = {
        'UserID': userID,
        'Role': 'user',
        'Email': email,
        'FullName': fullName,
        'PhoneNumber': phoneNumber,
        'CreatedAt': FieldValue.serverTimestamp(),
        'LastLogin': FieldValue.serverTimestamp(),
        'Status': 'active',
        'ProfileImage': imageUrl,
      };

      // บันทึกข้อมูลผู้ใช้ลง Firestore
      await _firestore.collection('users').doc(uid).set(userData);

      print("✅ สมัครและอัปโหลดรูปภาพเรียบร้อยแล้ว");
    } catch (e) {
      print("❌ เกิดข้อผิดพลาดขณะสมัคร: $e");
      rethrow;
    }
  }

  /// ดึงข้อมูลผู้ใช้ปัจจุบันจาก Firestore
  static Future<Map<String, dynamic>?> getCurrentUserData() async {
    try {
      final User? user = _auth.currentUser;
      if (user != null) {
        final DocumentSnapshot doc =
            await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists) return doc.data() as Map<String, dynamic>;
      }
    } catch (e) {
      print('❌ เกิดข้อผิดพลาดขณะดึงข้อมูลผู้ใช้: $e');
    }
    return null;
  }

  /// ออกจากระบบ
  static Future<void> logout() async {
    try {
      await _auth.signOut();
      print("🚪 ออกจากระบบเรียบร้อยแล้ว");
    } catch (e) {
      print("❌ ออกจากระบบไม่สำเร็จ: $e");
    }
  }

  /// ผู้ใช้ปัจจุบัน
  static User? get currentUser => _auth.currentUser;
}
