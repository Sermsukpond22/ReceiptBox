import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class EditProfilePage extends StatefulWidget {
  final Map<String, dynamic> userData;
  EditProfilePage({required this.userData});

  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  TextEditingController nameController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  File? _imageFile;

  @override
  void initState() {
    super.initState();
    nameController.text = widget.userData['FullName'] ?? '';
    phoneController.text = widget.userData['PhoneNumber'] ?? '';
  }

  Future<void> pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _imageFile = File(picked.path);
      });
    }
  }

  Future<void> saveProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    String? profileImageUrl = widget.userData['ProfileImage'];

    try {
      if (_imageFile != null && user != null) {
        final ref = FirebaseStorage.instance.ref('profile_images/${user.uid}');
        await ref.putFile(_imageFile!);
        profileImageUrl = await ref.getDownloadURL();
      }

      await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({
        'FullName': nameController.text.trim(),
        'PhoneNumber': phoneController.text.trim(),
        'ProfileImage': profileImageUrl,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('บันทึกข้อมูลเรียบร้อย')),
      );

      Navigator.pop(context);
    } catch (e) {
      print('เกิดข้อผิดพลาด: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาดในการบันทึก')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileImageUrl = widget.userData['ProfileImage'];

    return Scaffold(
      appBar: AppBar(title: Text('แก้ไขโปรไฟล์')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            children: [
              GestureDetector(
                onTap: pickImage,
                child: CircleAvatar(
                  radius: 60,
                  backgroundImage: _imageFile != null
                      ? FileImage(_imageFile!)
                      : (profileImageUrl != null && profileImageUrl != '')
                          ? NetworkImage(profileImageUrl)
                          : null,
                  child: (_imageFile == null && (profileImageUrl == null || profileImageUrl == ''))
                      ? Icon(Icons.person, size: 60)
                      : null,
                ),
              ),
              SizedBox(height: 20),
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: 'ชื่อ-นามสกุล'),
              ),
              SizedBox(height: 10),
              TextField(
                controller: phoneController,
                decoration: InputDecoration(labelText: 'เบอร์โทร'),
                keyboardType: TextInputType.phone,
              ),
              SizedBox(height: 10),
              TextField(
                enabled: false,
                decoration: InputDecoration(
                  labelText: 'อีเมล',
                  hintText: widget.userData['Email'] ?? '',
                  disabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: saveProfile,
                child: Text('บันทึกการเปลี่ยนแปลง'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
