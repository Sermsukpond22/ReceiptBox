import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cool_alert/cool_alert.dart';
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
  bool isLoading = false;  // Variable to handle loading state

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> registerUser() async {
    setState(() {
      isNameValid = nameController.text.trim().isNotEmpty;
      isPhoneValid = RegExp(r'^[0-9]{9,10}$').hasMatch(phoneController.text.trim()); // Phone validation
      isEmailValid = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(emailController.text.trim()); // Email validation
      isPasswordValid = passwordController.text.length >= 6;
      isConfirmPasswordValid = passwordController.text == confirmPasswordController.text;
    });

    if (isNameValid && isPhoneValid && isEmailValid && isPasswordValid && isConfirmPasswordValid) {
      setState(() {
        isLoading = true;  // Disable button when loading
      });

      try {
        // Register user in Firebase
        UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );

        await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
          'uid': userCredential.user!.uid,
          'name': nameController.text.trim(),
          'phone': phoneController.text.trim(),
          'email': emailController.text.trim(),
          'created_at': Timestamp.now(),
        });

        if (mounted) {
          CoolAlert.show(
            context: context,
            type: CoolAlertType.success,
            title: 'สมัครสมาชิกสำเร็จ',
            text: 'กำลังไปที่หน้าล็อกอิน...',
            autoCloseDuration: Duration(seconds: 2),
          );

          // Navigate to login screen after a delay
          Future.delayed(Duration(seconds: 2), () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => LoginScreen()),
            );
          });
        }

        // Clear form fields after successful registration
        nameController.clear();
        phoneController.clear();
        emailController.clear();
        passwordController.clear();
        confirmPasswordController.clear();

      } on FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use') {
          CoolAlert.show(
            context: context,
            type: CoolAlertType.warning,
            title: 'อีเมลนี้ถูกใช้แล้ว',
            text: 'กรุณาใช้อีเมลอื่น',
          );
        } else {
          CoolAlert.show(
            context: context,
            type: CoolAlertType.error,
            title: 'เกิดข้อผิดพลาด',
            text: e.message ?? 'ไม่สามารถสมัครสมาชิกได้',
          );
        }
      } finally {
        setState(() {
          isLoading = false;  // Re-enable button after processing
        });
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
              onPressed: isLoading ? null : registerUser,  // Disable button when loading
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: isLoading
                  ? CircularProgressIndicator(color: Colors.white)  // Show progress indicator while loading
                  : Text(
                      'สมัครสมาชิก',
                      style: TextStyle(fontSize: 18),
                    ),
            ),
            SizedBox(height: 20),
            TextButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                );
              },
              child: Text(
                'มีบัญชีอยู่แล้ว? เข้าสู่ระบบ',
                style: TextStyle(color: Colors.blueAccent),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
