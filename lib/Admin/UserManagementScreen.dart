// lib/Screen/UserManagementScreen.dart
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

  // Function to delete user account
  Future<void> _deleteUser(String userId, String email) async {
    CoolAlert.show(
      context: context,
      type: CoolAlertType.confirm,
      title: 'ยืนยันการลบ',
      text: 'คุณแน่ใจหรือไม่ที่จะลบผู้ใช้ ${email}?',
      confirmBtnText: 'ใช่, ลบ',
      cancelBtnText: 'ยกเลิก',
      confirmBtnColor: Colors.red, // Make the confirm button red for deletion
      onConfirmBtnTap: () async {
        try {
          // As noted, client-side Firebase Auth doesn't have a direct API to delete other users.
          // Deleting a user from Firebase Auth should be done via Cloud Functions or Admin SDK for security.
          // For this demo, we'll only delete the Firestore data and alert about Auth deletion.
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

  // Function to reset user password
  // **Caution:** Directly changing another user's password via Client-side Firebase Auth API is not possible.
  // You should use more secure methods like:
  // 1. Sending a password reset email to the user (user must act on it).
  // 2. Creating a Cloud Function that uses Firebase Admin SDK to change the password.
  // For this demo, we'll show sending a password reset email.
  Future<void> _resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      CoolAlert.show(
        context: context,
        type: CoolAlertType.success,
        title: 'ส่งอีเมลรีเซ็ตรหัสผ่านแล้ว',
        text:
            'ได้ส่งอีเมลรีเซ็ตรหัสผ่านไปยัง ${email} เรียบร้อยแล้ว. ผู้ใช้จะต้องดำเนินการตามลิงก์ในอีเมล.',
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
      backgroundColor: Colors.grey[50], // Lighter background for the entire screen
      appBar: AppBar(
        title: Text(
          'จัดการผู้ใช้',
          style: GoogleFonts.prompt(
            fontWeight: FontWeight.w600, // Make app bar title bolder
            color: Colors.white, // Text color for app bar
          ),
        ),
        backgroundColor: Colors.indigo, // Consistent app bar color
        elevation: 0, // Flat design for app bar
        centerTitle: true, // Center the title
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            _firestore.collection('users').where('Role', isEqualTo: 'user').snapshots(),
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
                  style: GoogleFonts.prompt(fontSize: 16, color: Colors.redAccent),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data == null || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                'ไม่พบข้อมูลผู้ใช้ทั่วไปในระบบ',
                style: GoogleFonts.prompt(fontSize: 18, color: Colors.grey[600]),
              ),
            );
          }

          final users = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16.0), // Padding around the list
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              final fullName = user['FullName'] ?? 'ไม่ระบุชื่อ';
              final email = user['Email'] ?? 'ไม่มีอีเมล'; // Default if email is missing

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                elevation: 3, // Add a subtle shadow to each user card
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12), // Rounded corners for cards
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                  child: Row(
                    children: [
                      // User Avatar (First letter of FullName or a default icon)
                      CircleAvatar(
                        backgroundColor: Colors.indigo.shade100,
                        foregroundColor: Colors.indigo.shade800,
                        radius: 24,
                        child: Text(
                          fullName.isNotEmpty ? fullName[0].toUpperCase() : '?',
                          style: GoogleFonts.prompt(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
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
                              overflow: TextOverflow.ellipsis, // Handle long names
                            ),
                            const SizedBox(height: 4),
                            Text(
                              email,
                              style: GoogleFonts.prompt(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                              overflow: TextOverflow.ellipsis, // Handle long emails
                            ),
                          ],
                        ),
                      ),
                      // Action Buttons
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Tooltip(
                            message: 'รีเซ็ตรหัสผ่าน',
                            child: IconButton(
                              icon: Icon(Icons.lock_reset, color: Colors.orange[700]),
                              onPressed: () => _resetPassword(email),
                              splashRadius: 24, // Visual feedback on tap
                            ),
                          ),
                          Tooltip(
                            message: 'ลบผู้ใช้',
                            child: IconButton(
                              icon: Icon(Icons.delete, color: Colors.red[700]),
                              onPressed: () => _deleteUser(user.id, email),
                              splashRadius: 24, // Visual feedback on tap
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