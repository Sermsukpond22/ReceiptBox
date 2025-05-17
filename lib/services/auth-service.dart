import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// สมัครผู้ใช้ใหม่
  static Future<void> registerUser({
    required String email,
    required String password,
    required String fullName,
    required String phoneNumber,
    required String profileImageUrl,
  }) async {
    try {
      final UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final String uid = userCredential.user!.uid;
      final String userID = const Uuid().v4();

      final Map<String, dynamic> userData = {
        'UserID': userID,
        'Role': 'user',
        'Email': email,
        'Password': '',
        'FullName': fullName,
        'PhoneNumber': phoneNumber,
        'CreatedAt': FieldValue.serverTimestamp(),
        'LastLogin': FieldValue.serverTimestamp(),
        'Status': 'active',
        'ProfileImage': profileImageUrl,
      };

      await _firestore.collection('users').doc(uid).set(userData);
      print("✅ สมัครและบันทึกข้อมูลผู้ใช้เรียบร้อยแล้ว");
    } catch (e) {
      print("❌ เกิดข้อผิดพลาดขณะสมัคร: $e");
      rethrow;
    }
  }

  /// ดึงข้อมูลผู้ใช้ปัจจุบันจาก Firestore
  static Future<Map<String, dynamic>?> getCurrentUserData() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        return doc.exists ? doc.data() : null;
      }
    } catch (e) {
      print('❌ เกิดข้อผิดพลาดขณะดึงข้อมูลผู้ใช้: $e');
    }
    return null;
  }

  /// ออกจากระบบ
  static Future<void> logout() async {
    await _auth.signOut();
  }

  /// ผู้ใช้ปัจจุบัน (FirebaseUser)
  static User? get currentUser => _auth.currentUser;
}
