import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<void> registerUser({
    required String email,
    required String password,
    required String fullName,
    required String phoneNumber,
  }) async {
    try {
      // สร้างผู้ใช้ใหม่ใน Firebase Authentication
      final UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      final String uid = userCredential.user!.uid;
      final String userID = const Uuid().v4();

      // เตรียมข้อมูลผู้ใช้ที่จะบันทึกใน Firestore
      final Map<String, dynamic> userData = {
        'UserID': userID,
        'Role': 'user',
        'Email': email,
        'Password': '', // ไม่ควรเก็บ password จริงไว้ใน Firestore
        'FullName': fullName,
        'PhoneNumber': phoneNumber,
        'CreatedAt': FieldValue.serverTimestamp(),
        'LastLogin': FieldValue.serverTimestamp(),
        'Status': 'active',
        'ProfileImage': '', // สามารถใส่ URL รูป default ได้ถ้ามี
      };

      // บันทึกข้อมูลผู้ใช้ลง Firestore โดยใช้ UID จาก Firebase Auth เป็น document ID
      await _firestore.collection('users').doc(uid).set(userData);

      print(" สมัครและบันทึกข้อมูลผู้ใช้เรียบร้อยแล้ว");

      // แสดง UID ของผู้ใช้ปัจจุบัน (สำหรับ debug)
      final User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        print(" Current UID: ${currentUser.uid}");
      } else {
        print(" No user is currently signed in.");
      }

    } catch (e) {
      print(" เกิดข้อผิดพลาดขณะสมัคร: $e");
      rethrow; // ส่ง error กลับไปให้ UI จัดการต่อ
    }
  }
}
