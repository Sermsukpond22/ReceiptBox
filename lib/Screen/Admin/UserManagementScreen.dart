// lib/Screen/UserManagementScreen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cool_alert/cool_alert.dart';
import 'package:firebase_auth/firebase_auth.dart'; // สำหรับการลบและเปลี่ยนรหัสผ่านของผู้ใช้

class UserManagementScreen extends StatefulWidget {
  @override
  _UserManagementScreenState createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ฟังก์ชันสำหรับลบบัญชีผู้ใช้
  Future<void> _deleteUser(String userId, String email) async {
    CoolAlert.show(
      context: context,
      type: CoolAlertType.confirm,
      title: 'ยืนยันการลบ',
      text: 'คุณแน่ใจหรือไม่ที่จะลบผู้ใช้ ${email}?',
      confirmBtnText: 'ใช่, ลบ',
      cancelBtnText: 'ยกเลิก',
      onConfirmBtnTap: () async {
        try {
          // Firebase Auth ไม่ได้มี API สำหรับลบผู้ใช้คนอื่นโดยตรงจากฝั่ง Client
          // การลบผู้ใช้จาก FirebaseAuth ควรทำผ่าน Cloud Functions หรือ Admin SDK เพื่อความปลอดภัย
          // สำหรับเดโม่นี้ จะลบแค่ข้อมูลใน Firestore และแจ้งเตือนว่าการลบใน Auth ต้องทำผ่าน Admin SDK
          await _firestore.collection('users').doc(userId).delete();

          // แจ้งเตือนเรื่องการลบใน Auth (ควรทำผ่าน Cloud Functions)
          CoolAlert.show(
            context: context,
            type: CoolAlertType.success,
            title: 'ลบข้อมูลสำเร็จ',
            text: 'ลบข้อมูลผู้ใช้จาก Firestore แล้ว. โปรดทราบว่าการลบบัญชีใน Firebase Authentication ต้องทำผ่าน Cloud Functions หรือ Firebase Admin SDK เพื่อความปลอดภัย.',
            autoCloseDuration: Duration(seconds: 5),
          );
        } catch (e) {
          CoolAlert.show(
            context: context,
            type: CoolAlertType.error,
            title: 'เกิดข้อผิดพลาด',
            text: 'ไม่สามารถลบผู้ใช้ได้: ${e.toString()}',
          );
        }
      },
    );
  }

  // ฟังก์ชันสำหรับเปลี่ยนรหัสผ่านผู้ใช้
  // **ข้อควรระวัง:** การเปลี่ยนรหัสผ่านผู้ใช้อื่นโดยตรงผ่าน Client-side Firebase Auth API นั้นทำไม่ได้
  // คุณจะต้องใช้วิธีที่ปลอดภัยกว่า เช่น:
  // 1. ส่งอีเมลรีเซ็ตรหัสผ่านไปยังผู้ใช้ (ซึ่งผู้ใช้ต้องดำเนินการเอง)
  // 2. สร้าง Cloud Function ที่ใช้ Firebase Admin SDK เพื่อเปลี่ยนรหัสผ่าน
  // สำหรับเดโม่นี้ จะแสดงการส่งอีเมลรีเซ็ตรหัสผ่าน
  Future<void> _resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      CoolAlert.show(
        context: context,
        type: CoolAlertType.success,
        title: 'ส่งอีเมลรีเซ็ตรหัสผ่านแล้ว',
        text: 'ได้ส่งอีเมลรีเซ็ตรหัสผ่านไปยัง ${email} เรียบร้อยแล้ว. ผู้ใช้จะต้องดำเนินการตามลิงก์ในอีเมล.',
        autoCloseDuration: Duration(seconds: 4),
      );
    } on FirebaseAuthException catch (e) {
      String message = 'ไม่สามารถส่งอีเมลรีเซ็ตรหัสผ่านได้: ${e.message}';
      if (e.code == 'user-not-found') {
        message = 'ไม่พบบัญชีผู้ใช้นี้ในระบบ Firebase Authentication.';
      }
      CoolAlert.show(
        context: context,
        type: CoolAlertType.error,
        title: 'เกิดข้อผิดพลาด',
        text: message,
      );
    } catch (e) {
      CoolAlert.show(
        context: context,
        type: CoolAlertType.error,
        title: 'เกิดข้อผิดพลาด',
        text: 'ไม่สามารถส่งอีเมลรีเซ็ตรหัสผ่านได้: ${e.toString()}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        // ดึงข้อมูลผู้ใช้ที่มี role เป็น 'user' และเรียงตาม FullName
        stream: _firestore.collection('users').where('Role', isEqualTo: 'user').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
                child: Text(
              'เกิดข้อผิดพลาด: ${snapshot.error}',
              style: GoogleFonts.prompt(),
            ));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
                child: Text(
              'ไม่พบข้อมูลผู้ใช้ทั่วไป',
              style: GoogleFonts.prompt(),
            ));
          }

          final users = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final userDoc = users[index];
              final userData = userDoc.data() as Map<String, dynamic>;

              return Card(
                margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ชื่อ: ${userData['FullName'] ?? 'ไม่ระบุ'}',
                        style: GoogleFonts.prompt(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'อีเมล: ${userData['Email'] ?? 'ไม่ระบุ'}',
                        style: GoogleFonts.prompt(fontSize: 14, color: Colors.grey[700]),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'สถานะ: ${userData['Status'] ?? 'ไม่ระบุ'}',
                        style: GoogleFonts.prompt(fontSize: 14, color: Colors.grey[700]),
                      ),
                      SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () => _resetPassword(userData['Email'] ?? ''),
                            icon: Icon(Icons.lock_reset, size: 18),
                            label: Text('เปลี่ยนรหัสผ่าน', style: GoogleFonts.prompt(fontSize: 12)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange[700],
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                          SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: () => _deleteUser(userDoc.id, userData['Email'] ?? ''),
                            icon: Icon(Icons.delete_forever, size: 18),
                            label: Text('ลบบัญชี', style: GoogleFonts.prompt(fontSize: 12)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red[700],
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}