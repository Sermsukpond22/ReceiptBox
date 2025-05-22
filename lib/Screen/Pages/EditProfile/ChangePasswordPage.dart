import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart'; // เพิ่ม Google Fonts เพื่อใช้กับ SnackBar และอื่นๆ

class ChangePasswordPage extends StatefulWidget {
  @override
  _ChangePasswordPageState createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final TextEditingController currentPasswordController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmNewPasswordController = TextEditingController();

  final _formKey = GlobalKey<FormState>(); // For form validation
  bool _isLoading = false;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmNewPassword = true;

  void changePassword() async {
    if (!_formKey.currentState!.validate()) {
      return; // Stop if validation fails
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception("User not logged in."); // ควรจะไม่เกิดขึ้นหากผู้ใช้เข้าถึงหน้านี้ได้
      }

      // Reauthenticate user with their current password
      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!, // สมมติว่าอีเมลของผู้ใช้พร้อมใช้งาน
        password: currentPasswordController.text.trim(),
      );

      await user.reauthenticateWithCredential(credential);

      // Update password
      await user.updatePassword(newPasswordController.text.trim());

      if (!mounted) return; // ตรวจสอบว่า widget ยังอยู่บน tree
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'เปลี่ยนรหัสผ่านเรียบร้อยแล้ว',
            style: GoogleFonts.prompt(), // ใช้ GoogleFonts.prompt สำหรับข้อความใน SnackBar
          ),
        ),
      );

      Navigator.pop(context); // กลับไปหน้าก่อนหน้าหลังจากเปลี่ยนสำเร็จ
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'ไม่สามารถเปลี่ยนรหัสผ่านได้';
      if (e.code == 'wrong-password') {
        errorMessage = 'รหัสผ่านปัจจุบันไม่ถูกต้อง';
      } else if (e.code == 'weak-password') {
        errorMessage = 'รหัสผ่านใหม่ไม่แข็งแรงพอ';
      } else if (e.code == 'requires-recent-login') {
        errorMessage = 'กรุณาเข้าสู่ระบบอีกครั้งเพื่อเปลี่ยนรหัสผ่าน';
        // คุณอาจจะต้องนำผู้ใช้ไปหน้า re-authentication ที่นี่
      } else {
        errorMessage = 'เกิดข้อผิดพลาด: ${e.message}';
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            errorMessage,
            style: GoogleFonts.prompt(),
          ),
        ),
      );
      print('เกิดข้อผิดพลาด: $e'); // สำหรับ debugging
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'เกิดข้อผิดพลาดที่ไม่คาดคิด: $e',
            style: GoogleFonts.prompt(),
          ),
        ),
      );
      print('เกิดข้อผิดพลาด: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmNewPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Scaffold background color จะถูกกำหนดจาก scaffoldBackgroundColor ใน main.dart
      appBar: AppBar(
        title: Text(
          'เปลี่ยนรหัสผ่าน',
          // ใช้ GoogleFonts.prompt สำหรับ title ใน AppBar เพื่อความสอดคล้อง
          style: GoogleFonts.prompt(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        // สีจะถูกกำหนดจาก AppBarTheme ใน main.dart
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: currentPasswordController,
                obscureText: _obscureCurrentPassword,
                style: GoogleFonts.prompt(), // กำหนด style ของข้อความที่กรอก
                decoration: InputDecoration(
                  labelText: 'รหัสผ่านปัจจุบัน',
                  labelStyle: GoogleFonts.prompt(), // กำหนด style ของ labelText
                  // border, filled, fillColor, focusedBorder, enabledBorder ฯลฯ จะถูกกำหนดจาก inputDecorationTheme ใน main.dart
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureCurrentPassword ? Icons.visibility_off : Icons.visibility,
                      color: Theme.of(context).primaryColor, // ใช้สีหลักจากธีม
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureCurrentPassword = !_obscureCurrentPassword;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'กรุณาใส่รหัสผ่านปัจจุบัน';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: newPasswordController,
                obscureText: _obscureNewPassword,
                style: GoogleFonts.prompt(),
                decoration: InputDecoration(
                  labelText: 'รหัสผ่านใหม่',
                  labelStyle: GoogleFonts.prompt(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureNewPassword ? Icons.visibility_off : Icons.visibility,
                      color: Theme.of(context).primaryColor,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureNewPassword = !_obscureNewPassword;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'กรุณาใส่รหัสผ่านใหม่';
                  }
                  if (value.length < 6) {
                    return 'รหัสผ่านต้องมีความยาวอย่างน้อย 6 ตัวอักษร';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: confirmNewPasswordController,
                obscureText: _obscureConfirmNewPassword,
                style: GoogleFonts.prompt(),
                decoration: InputDecoration(
                  labelText: 'ยืนยันรหัสผ่านใหม่',
                  labelStyle: GoogleFonts.prompt(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmNewPassword ? Icons.visibility_off : Icons.visibility,
                      color: Theme.of(context).primaryColor,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmNewPassword = !_obscureConfirmNewPassword;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'กรุณายืนยันรหัสผ่านใหม่';
                  }
                  if (value != newPasswordController.text) {
                    return 'รหัสผ่านใหม่ไม่ตรงกัน';
                  }
                  return null;
                },
              ),
              SizedBox(height: 30),
              _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor), // ใช้สีหลักจากธีม
                      ),
                    )
                  : ElevatedButton(
                      onPressed: changePassword,
                      style: ElevatedButton.styleFrom(
                        // ไม่ต้องกำหนด backgroundColor, foregroundColor, shape, minimumSize, textStyle ที่นี่
                        // เพราะถูกกำหนดใน elevatedButtonTheme ใน main.dart แล้ว
                        padding: EdgeInsets.symmetric(vertical: 15), // สามารถปรับ padding ได้หากต้องการ
                        elevation: 2.0, // สามารถปรับ elevation ได้
                      ),
                      child: Text(
                        'บันทึกรหัสผ่าน',
                        // style ของ Text จะถูกกำหนดจาก elevatedButtonTheme ใน main.dart
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}