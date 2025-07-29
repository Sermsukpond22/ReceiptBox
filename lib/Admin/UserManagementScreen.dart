import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cool_alert/cool_alert.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserManagementScreen extends StatefulWidget {
  @override
  _UserManagementScreenState createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _deleteUser(String userId, String email) async {
    CoolAlert.show(
      context: context,
      type: CoolAlertType.confirm,
      title: 'ยืนยันการลบ',
      text: 'คุณแน่ใจหรือไม่ที่จะลบผู้ใช้ $email?',
      confirmBtnText: 'ใช่, ลบ',
      cancelBtnText: 'ยกเลิก',
      confirmBtnColor: Colors.red,
      onConfirmBtnTap: () async {
        try {
          await _firestore.collection('users').doc(userId).delete();
          CoolAlert.show(
            context: context,
            type: CoolAlertType.success,
            title: 'ลบข้อมูลสำเร็จ',
            text:
                'ลบข้อมูลผู้ใช้จาก Firestore แล้ว. โปรดทราบว่าการลบบัญชีใน Firebase Authentication ต้องทำผ่าน Cloud Functions หรือ Firebase Admin SDK เพื่อความปลอดภัย.',
            autoCloseDuration: const Duration(seconds: 5),
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

  Future<void> _resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      CoolAlert.show(
        context: context,
        type: CoolAlertType.success,
        title: 'ส่งอีเมลรีเซ็ตรหัสผ่านแล้ว',
        text: 'ได้ส่งอีเมลรีเซ็ตรหัสผ่านไปยัง $email เรียบร้อยแล้ว.',
        autoCloseDuration: const Duration(seconds: 4),
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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'จัดการผู้ใช้',
          style: GoogleFonts.prompt(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.indigo,
        elevation: 0,
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('users')
            .where('Role', isEqualTo: 'user')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'เกิดข้อผิดพลาดในการโหลดข้อมูล: ${snapshot.error}',
                  style:
                      GoogleFonts.prompt(fontSize: 16, color: Colors.redAccent),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (!snapshot.hasData ||
              snapshot.data == null ||
              snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                'ไม่พบข้อมูลผู้ใช้ทั่วไปในระบบ',
                style:
                    GoogleFonts.prompt(fontSize: 18, color: Colors.grey[600]),
              ),
            );
          }

          final users = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              final fullName = user['FullName'] ?? 'ไม่ระบุชื่อ';
              final email = user['Email'] ?? 'ไม่มีอีเมล';
              final profileImage = user['ProfileImage']?.toString();

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                  child: Row(
                    children: [
                      // แสดงรูปโปรไฟล์หรือ default avatar
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.grey.shade200,
                        backgroundImage: profileImage != null && profileImage.isNotEmpty
                            ? NetworkImage(profileImage)
                            : const NetworkImage('https://i.pravatar.cc/150?u=default'),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              fullName,
                              style: GoogleFonts.prompt(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[800],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              email,
                              style: GoogleFonts.prompt(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Tooltip(
                            message: 'รีเซ็ตรหัสผ่าน',
                            child: IconButton(
                              icon: Icon(Icons.lock_reset,
                                  color: Colors.orange[700]),
                              onPressed: () => _resetPassword(email),
                              splashRadius: 24,
                            ),
                          ),
                          Tooltip(
                            message: 'ลบผู้ใช้',
                            child: IconButton(
                              icon:
                                  Icon(Icons.delete, color: Colors.red[700]),
                              onPressed: () => _deleteUser(user.id, email),
                              splashRadius: 24,
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