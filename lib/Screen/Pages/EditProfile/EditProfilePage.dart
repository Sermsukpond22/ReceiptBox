import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_fonts/google_fonts.dart';

class EditProfilePage extends StatefulWidget {
  final Map<String, dynamic> userData;
  EditProfilePage({required this.userData});

  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  File? _imageFile;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    nameController.text = widget.userData['FullName'] ?? '';
    phoneController.text = widget.userData['PhoneNumber'] ?? '';
    emailController.text = widget.userData['Email'] ?? '';
  }

  Future<void> pickImage() async {
    if (_isSaving) return;
    try {
      final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (picked != null) {
        setState(() {
          _imageFile = File(picked.path);
        });
      }
    } catch (e) {
      print('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'ไม่สามารถเลือกรูปได้',
              // ใช้ Theme.of(context).textTheme.bodyText2 เพื่อให้สอดคล้องกับธีมหลัก
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        );
      }
    }
  }

  Future<void> saveProfile() async {
    if (nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'กรุณากรอกชื่อ-นามสกุล',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final user = FirebaseAuth.instance.currentUser;
    String? profileImageUrl = widget.userData['ProfileImage'];

    try {
      if (_imageFile != null && user != null) {
        final ref = FirebaseStorage.instance.ref().child('profile_images/${user.uid}');
        await ref.putFile(_imageFile!);
        profileImageUrl = await ref.getDownloadURL();
      }

      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'FullName': nameController.text.trim(),
          'PhoneNumber': phoneController.text.trim(),
          'ProfileImage': profileImageUrl,
        });
      } else {
        throw Exception("User not found");
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'บันทึกข้อมูลเรียบร้อย',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      print('เกิดข้อผิดพลาด: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'เกิดข้อผิดพลาดในการบันทึก: $e',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  // ใช้ TextField โดยตรงและอาศัย InputDecorationTheme จาก MaterialApp
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
    bool enabled = true,
    IconData? prefixIcon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: TextField(
        controller: controller,
        enabled: enabled,
        // ใช้ style จาก Theme.of(context).textTheme หรือ GoogleFonts.prompt
        style: GoogleFonts.prompt(color: enabled ? Colors.black87 : Colors.grey[700]),
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          // labelStyle จะถูกกำหนดจาก inputDecorationTheme ใน main.dart
          prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null, // สีไอคอนจะมาจาก Theme.of(context).primaryColor
          // border, filled, fillColor, disabledBorder, focusedBorder, enabledBorder
          // จะถูกกำหนดจาก inputDecorationTheme ใน main.dart โดยอัตโนมัติ
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentProfileImageUrl = widget.userData['ProfileImage'] as String?;

    return Scaffold(
      // Scaffold background color จะถูกกำหนดจาก scaffoldBackgroundColor ใน main.dart
      appBar: AppBar(
        title: Text(
          'แก้ไขโปรไฟล์',
          // ใช้ style จาก Theme.of(context).appBarTheme.titleTextStyle หรือ GoogleFonts.prompt
          style: GoogleFonts.prompt(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        // สีจะถูกกำหนดจาก AppBarTheme ใน main.dart
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 20),
              GestureDetector(
                onTap: _isSaving ? null : pickImage, // ป้องกันการแตะขณะกำลังบันทึก
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircleAvatar(
                      radius: 70,
                      backgroundColor: Colors.grey.shade300,
                      backgroundImage: _imageFile != null
                          ? FileImage(_imageFile!) as ImageProvider
                          : (currentProfileImageUrl != null && currentProfileImageUrl.isNotEmpty)
                              ? NetworkImage(currentProfileImageUrl)
                              : null, // สามารถใส่ AssetImage หรือ NetworkImage สำหรับ default avatar
                      child: (_imageFile == null && (currentProfileImageUrl == null || currentProfileImageUrl.isEmpty))
                          ? Icon(Icons.person, size: 80, color: Colors.grey.shade500)
                          : null,
                    ),
                    Positioned(
                      bottom: 5,
                      right: 5,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor, // ใช้สีหลักจาก Theme
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        padding: EdgeInsets.all(8),
                        child: Icon(Icons.camera_alt, color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 30),
              _buildTextField(
                controller: nameController,
                label: 'ชื่อ-นามสกุล',
                prefixIcon: Icons.person_outline,
              ),
              _buildTextField(
                controller: phoneController,
                label: 'เบอร์โทร',
                keyboardType: TextInputType.phone,
                prefixIcon: Icons.phone_outlined,
              ),
              _buildTextField(
                controller: emailController,
                label: 'อีเมล',
                enabled: false, // อีเมลแก้ไขไม่ได้
                prefixIcon: Icons.email_outlined,
              ),
              SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: _isSaving ? SizedBox.shrink() : Icon(Icons.save_outlined), // สีไอคอนจะถูกกำหนดโดย foregroundColor ของ ElevatedButtonTheme
                  label: _isSaving
                      ? SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.onPrimary), // ใช้สีข้อความบนปุ่ม
                          ),
                        )
                      : Text(
                          'บันทึกการเปลี่ยนแปลง',
                          // style จะถูกกำหนดจาก ElevatedButtonThemeData ใน main.dart
                        ),
                  onPressed: _isSaving ? null : saveProfile,
                  style: ElevatedButton.styleFrom(
                    // ไม่ต้องกำหนด backgroundColor, foregroundColor, shape, minimumSize, textStyle ที่นี่
                    // เพราะถูกกำหนดใน elevatedButtonTheme ใน main.dart แล้ว
                    padding: EdgeInsets.symmetric(vertical: 14), // สามารถปรับ padding ได้หากต้องการ
                    elevation: 2.0, // สามารถปรับ elevation ได้
                  ),
                ),
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}