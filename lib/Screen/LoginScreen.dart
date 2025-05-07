import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cool_alert/cool_alert.dart'; // สำหรับแจ้งเตือนแบบสวยงาม
import 'package:run_android/Screen/RegisterScreen.dart';
import 'HomeScreen.dart'; // หน้า HomeScreen


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
    return Scaffold(
      backgroundColor: Colors.blue[50],
      appBar: AppBar(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        title: Text('เข้าสู่ระบบ'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 50),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Text(
                  'ยินดีต้อนรับกลับมา!',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[900],
                  ),
                ),
              ),
              SizedBox(height: 40),
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: 'อีเมล',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              SizedBox(height: 20),
              TextField(
                controller: passwordController,
                decoration: InputDecoration(
                  labelText: 'รหัสผ่าน',
                  prefixIcon: Icon(Icons.lock),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                obscureText: true,
              ),
              SizedBox(height: 30),
              ElevatedButton(
                onPressed: isLoading
                    ? null
                    : () async {
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
                            await FirebaseAuth.instance
                                .signInWithEmailAndPassword(
                              email: email,
                              password: password,
                            );

                            // แสดง CoolAlert แบบสำเร็จ และปิดอัตโนมัติ
                            CoolAlert.show(
                              context: context,
                              type: CoolAlertType.success,
                              title: 'เข้าสู่ระบบสำเร็จ',
                              text: 'กำลังนำคุณไปยังหน้าหลัก',
                              autoCloseDuration: Duration(seconds: 2), // ปิดอัตโนมัติหลัง 2 วินาที
                            );

                            // รอ 2 วินาทีก่อนเปลี่ยนหน้า
                            await Future.delayed(Duration(seconds: 2));
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => HomeScreen()),
                            );
                          } on FirebaseAuthException catch (e) {
                            String message = '';
                            switch (e.code) {
                              case 'user-not-found':
                                message = 'ไม่พบบัญชีผู้ใช้นี้';
                                break;
                              case 'wrong-password':
                                message = 'รหัสผ่านไม่ถูกต้อง';
                                break;
                              default:
                                message = 'เกิดข้อผิดพลาด: ${e.message}';
                            }

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
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  minimumSize: Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text(
                        'เข้าสู่ระบบ',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
              SizedBox(height: 20),
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => RegisterScreen()),
                    );
                  },
                  child: Text('ยังไม่มีบัญชี? สมัครสมาชิก'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
