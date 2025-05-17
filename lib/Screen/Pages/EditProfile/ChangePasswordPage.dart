import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChangePasswordPage extends StatefulWidget {
  @override
  _ChangePasswordPageState createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final TextEditingController newPasswordController = TextEditingController();

  void changePassword() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      await user?.updatePassword(newPasswordController.text.trim());

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เปลี่ยนรหัสผ่านเรียบร้อยแล้ว')),
      );

      Navigator.pop(context);
    } catch (e) {
      print('เกิดข้อผิดพลาด: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ไม่สามารถเปลี่ยนรหัสผ่านได้')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('เปลี่ยนรหัสผ่าน')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: newPasswordController,
              obscureText: true,
              decoration: InputDecoration(labelText: 'รหัสผ่านใหม่'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: changePassword,
              child: Text('บันทึกรหัสผ่าน'),
            ),
          ],
        ),
      ),
    );
  }
}
