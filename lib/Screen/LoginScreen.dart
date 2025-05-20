import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cool_alert/cool_alert.dart';
import 'package:run_android/Screen/Admin/AdminScreen.dart';
import 'package:run_android/Screen/RegisterScreen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'HomeScreen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;

  bool isEmailValid(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email.trim());
  }

  @override
  Widget build(BuildContext context) {
    // ... your existing build method
    return Scaffold(
      backgroundColor: Colors.blue[50],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.blue,
        title: Text(
          'เข้าสู่ระบบ',
          style: GoogleFonts.prompt(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Text(
                'ยินดีต้อนรับกลับมา!',
                style: GoogleFonts.prompt(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[900],
                ),
              ),
            ),
            SizedBox(height: 40),
            TextField(
              controller: emailController,
              style: GoogleFonts.prompt(),
              decoration: InputDecoration(
                labelText: 'อีเมล',
                labelStyle: GoogleFonts.prompt(),
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: 20),
            TextField(
              controller: passwordController,
              style: GoogleFonts.prompt(),
              decoration: InputDecoration(
                labelText: 'รหัสผ่าน',
                labelStyle: GoogleFonts.prompt(),
                prefixIcon: Icon(Icons.lock),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
              obscureText: true,
            ),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: isLoading ? null : _login,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                minimumSize: Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: isLoading
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text(
                      'เข้าสู่ระบบ',
                      style: GoogleFonts.prompt(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
            SizedBox(height: 20),
            Center(
              child: TextButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => RegisterScreen()));
                },
                child: Text(
                  'ยังไม่มีบัญชี? สมัครสมาชิก',
                  style: GoogleFonts.prompt(fontSize: 14, color: Colors.blue[700]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _login() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (!isEmailValid(email)) {
      CoolAlert.show(
        context: context,
        type: CoolAlertType.warning,
        title: 'อีเมลไม่ถูกต้อง',
        text: 'กรุณากรอกอีเมลให้ถูกต้อง',
      );
      return;
    }

    if (email.isNotEmpty && password.isNotEmpty) {
      setState(() => isLoading = true);

      try {
        UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);
        
        // --- START: Admin Role Check ---
        if (userCredential.user != null) {
          DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).get();

          if (userDoc.exists && userDoc.data() != null) {
            Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
            String? role = userData['Role'];

            CoolAlert.show(
              context: context,
              type: CoolAlertType.success,
              title: 'เข้าสู่ระบบสำเร็จ',
              text: 'กำลังนำคุณไปยังหน้าหลัก',
              autoCloseDuration: Duration(seconds: 2),
            );

            await Future.delayed(Duration(seconds: 2));

            if (role == 'admin') {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => AdminScreen()));
            } else {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomeScreen()));
            }
          } else {
            // If user document doesn't exist in Firestore, treat as a regular user or handle as an error
            CoolAlert.show(
              context: context,
              type: CoolAlertType.success,
              title: 'เข้าสู่ระบบสำเร็จ',
              text: 'กำลังนำคุณไปยังหน้าหลัก (ผู้ใช้ทั่วไป)',
              autoCloseDuration: Duration(seconds: 2),
            );
            await Future.delayed(Duration(seconds: 2));
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomeScreen()));
          }
        }
        // --- END: Admin Role Check ---

      } on FirebaseAuthException catch (e) {
        String message = switch (e.code) {
          'user-not-found' => 'ไม่พบบัญชีผู้ใช้นี้',
          'wrong-password' => 'รหัสผ่านไม่ถูกต้อง',
          'invalid-email' => 'รูปแบบอีเมลไม่ถูกต้อง', // Add this case for clarity
          _ => 'เกิดข้อผิดพลาด: ${e.message}',
        };

        CoolAlert.show(
          context: context,
          type: CoolAlertType.error,
          title: 'เกิดข้อผิดพลาด',
          text: message,
        );
      } finally {
        setState(() => isLoading = false);
      }
    } else {
      CoolAlert.show(
        context: context,
        type: CoolAlertType.warning,
        title: 'กรุณากรอกข้อมูลให้ครบถ้วน',
        text: 'กรุณากรอกอีเมลและรหัสผ่านให้ครบถ้วน',
      );
    }
  }
}