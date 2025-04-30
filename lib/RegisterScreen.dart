import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'LoginScreen.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  bool isNameValid = true;
  bool isPhoneValid = true;
  bool isEmailValid = true;
  bool isPasswordValid = true;
  bool isConfirmPasswordValid = true;

  Future<void> registerUser() async {
    setState(() {
      isNameValid = nameController.text.trim().isNotEmpty;
      isPhoneValid = phoneController.text.trim().isNotEmpty;
      isEmailValid = emailController.text.contains('@');
      isPasswordValid = passwordController.text.length >= 6;
      isConfirmPasswordValid = passwordController.text == confirmPasswordController.text;
    });

    if (isNameValid && isPhoneValid && isEmailValid && isPasswordValid && isConfirmPasswordValid) {
      try {
        // Firebase Auth
        UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );

        // Firestore
        await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
          'uid': userCredential.user!.uid,
          'name': nameController.text.trim(),
          'phone': phoneController.text.trim(),
          'email': emailController.text.trim(),
          'created_at': Timestamp.now(),
        });

        // แสดงข้อความสำเร็จ แล้วเด้งไปหน้า Login
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('สมัครสมาชิกสำเร็จ!')),
          );

          // ล้างฟอร์ม
          nameController.clear();
          phoneController.clear();
          emailController.clear();
          passwordController.clear();
          confirmPasswordController.clear();

          // รอให้ SnackBar แสดงก่อน แล้วค่อยไปหน้า Login
          await Future.delayed(Duration(seconds: 2));

          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => LoginScreen()),
            );
          }
        }
      } on FirebaseAuthException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.message ?? 'เกิดข้อผิดพลาด')),
          );
        }
      }
    }
  }

  Widget buildTextField({
    required TextEditingController controller,
    required String labelText,
    required String hintText,
    bool isPassword = false,
    bool isValid = true,
    String? errorText,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        decoration: InputDecoration(
          labelText: labelText,
          hintText: hintText,
          errorText: isValid ? null : errorText,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.blueAccent, width: 2),
          ),
          labelStyle: TextStyle(color: Colors.blueAccent),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('สมัครสมาชิก'),
        backgroundColor: Colors.blueAccent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            buildTextField(
              controller: nameController,
              labelText: 'ชื่อ-นามสกุล',
              hintText: 'กรอกชื่อของคุณ',
              isValid: isNameValid,
              errorText: 'กรุณากรอกชื่อ',
            ),
            buildTextField(
              controller: phoneController,
              labelText: 'เบอร์โทรศัพท์',
              hintText: 'กรอกเบอร์โทร',
              isValid: isPhoneValid,
              errorText: 'กรุณากรอกเบอร์โทรศัพท์',
            ),
            buildTextField(
              controller: emailController,
              labelText: 'อีเมล',
              hintText: 'example@gmail.com',
              isValid: isEmailValid,
              errorText: 'อีเมลไม่ถูกต้อง',
            ),
            buildTextField(
              controller: passwordController,
              labelText: 'รหัสผ่าน',
              hintText: '********',
              isPassword: true,
              isValid: isPasswordValid,
              errorText: 'รหัสผ่านต้องมากกว่า 6 ตัวอักษร',
            ),
            buildTextField(
              controller: confirmPasswordController,
              labelText: 'ยืนยันรหัสผ่าน',
              hintText: '********',
              isPassword: true,
              isValid: isConfirmPasswordValid,
              errorText: 'รหัสผ่านไม่ตรงกัน',
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: registerUser,
              child: Text('สมัครสมาชิก'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
