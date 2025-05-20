import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cool_alert/cool_alert.dart';
import 'package:google_fonts/google_fonts.dart';


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

  File? _profileImage;
  final picker = ImagePicker();

  bool isNameValid = true;
  bool isPhoneValid = true;
  bool isEmailValid = true;
  bool isPasswordValid = true;
  bool isConfirmPasswordValid = true;
  bool isLoading = false;

  Future<void> pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  Future<String?> uploadProfileImage(String uid) async {
    if (_profileImage == null) return null; // Allow null image

    try {
      final ref = FirebaseStorage.instance.ref().child('profile_images/$uid.jpg');
      await ref.putFile(_profileImage!);
      return await ref.getDownloadURL();
    } catch (e) {
      print('Image upload error: $e');
      return null;
    }
  }

  Future<void> registerUser() async {
    setState(() {
      isNameValid = nameController.text.trim().isNotEmpty;
      isPhoneValid = RegExp(r'^[0-9]{9,10}$').hasMatch(phoneController.text.trim());
      isEmailValid = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(emailController.text.trim());
      isPasswordValid = passwordController.text.length >= 6;
      isConfirmPasswordValid = passwordController.text == confirmPasswordController.text;
    });

    if (!isNameValid || !isPhoneValid || !isEmailValid || !isPasswordValid || !isConfirmPasswordValid) {
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
              email: emailController.text.trim(),
              password: passwordController.text.trim());

      final String uid = userCredential.user!.uid;
      final String? imageUrl = await uploadProfileImage(uid); // Pass uid

      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'UserID': uid,
        'Role': 'user',
        'Email': emailController.text.trim(),
        'FullName': nameController.text.trim(),
        'PhoneNumber': phoneController.text.trim(),
        'CreatedAt': FieldValue.serverTimestamp(),
        'LastLogin': FieldValue.serverTimestamp(),
        'Status': 'active',
        'ProfileImage': imageUrl ?? '', // Use null-aware operator
      });

      CoolAlert.show(
        context: context,
        type: CoolAlertType.success,
        text: "สมัครสมาชิกสำเร็จ!",
        confirmBtnColor: Colors.green,
        onConfirmBtnTap: () {
          Navigator.of(context).popUntil((route) => route.isFirst);
        },
      );
    } on FirebaseAuthException catch (e) {
      CoolAlert.show(
        context: context,
        type: CoolAlertType.error,
        title: "เกิดข้อผิดพลาด",
        text: e.message ?? "ไม่สามารถสมัครสมาชิกได้",
      );
    } catch (e) {
      CoolAlert.show(
        context: context,
        type: CoolAlertType.error,
        title: "เกิดข้อผิดพลาด",
        text: "บางอย่างผิดพลาด: $e",
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget buildTextField(String label, TextEditingController controller, bool showError,
      {bool obscureText = false, TextInputType keyboardType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: GoogleFonts.prompt(),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey[700]),
          errorText: showError ? 'กรุณากรอกข้อมูลให้ถูกต้อง' : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.grey.shade100,
        ),
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[50],
      appBar: AppBar(
        title: Text("สมัครสมาชิก", style: GoogleFonts.prompt(fontWeight: FontWeight.w600)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            GestureDetector(
              onTap: pickImage,
              child: CircleAvatar(
                radius: 55,
                backgroundColor: Colors.blueAccent.shade100,
                backgroundImage: _profileImage != null ? FileImage(_profileImage!) : null,
                child: _profileImage == null
                    ? Icon(Icons.camera_alt, size: 40, color: Colors.white)
                    : null,
              ),
            ),
            SizedBox(height: 20),
            buildTextField("ชื่อ-นามสกุล", nameController, !isNameValid),
            buildTextField("เบอร์โทร", phoneController, !isPhoneValid, keyboardType: TextInputType.phone),
            buildTextField("อีเมล", emailController, !isEmailValid, keyboardType: TextInputType.emailAddress),
            buildTextField("รหัสผ่าน", passwordController, !isPasswordValid, obscureText: true),
            buildTextField("ยืนยันรหัสผ่าน", confirmPasswordController, !isConfirmPasswordValid, obscureText: true),
            SizedBox(height: 25),
            isLoading
                ? CircularProgressIndicator()
                : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: registerUser,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        "สมัครสมาชิก",
                        style: GoogleFonts.prompt(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
