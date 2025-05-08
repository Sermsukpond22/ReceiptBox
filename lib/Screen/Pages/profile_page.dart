import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? userData;
  bool isLoading = true;
  bool isEditing = false; // ควบคุมโหมดการแก้ไข
  TextEditingController fullNameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        DocumentSnapshot doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (doc.exists) {
          if (mounted) { // ตรวจสอบว่า widget ยังอยู่ใน widget tree หรือไม่
            setState(() {
              userData = doc.data() as Map<String, dynamic>;
              fullNameController.text = userData!['name'] ?? '';
              isLoading = false;
            });
          }
        }
      }
    } catch (e) {
      print('เกิดข้อผิดพลาดในการโหลดข้อมูลผู้ใช้: $e');
      if (mounted) { // ตรวจสอบว่า widget ยังอยู่ใน widget tree หรือไม่
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushReplacementNamed('/login'); // หรือเปลี่ยนเป็น route ของคุณ
  }

  // ฟังก์ชันสำหรับบันทึกการแก้ไข
  void saveChanges() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null && fullNameController.text.isNotEmpty) {
        // อัปเดตข้อมูลใน Firestore
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'FullName': fullNameController.text,
          'Password': passwordController.text, // อัปเดตรหัสผ่าน (อาจต้องเข้ารหัสก่อน)
        });

        // แสดงข้อความสำเร็จ
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ข้อมูลได้รับการอัปเดตแล้ว!')),
        );

        setState(() {
          isEditing = false;
        });
      }
    } catch (e) {
      print('เกิดข้อผิดพลาดในการบันทึกข้อมูล: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (userData == null) {
      return Center(child: Text('ไม่พบข้อมูลผู้ใช้'));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('โปรไฟล์'),
        actions: [
          IconButton(
            icon: Icon(Icons.exit_to_app),
            onPressed: logout, // ปุ่มออกจากระบบ
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // รูปโปรไฟล์
              CircleAvatar(
                radius: 60,
                backgroundImage: userData!['ProfileImage'] != null
                    ? NetworkImage(userData!['ProfileImage'])
                    : null,
                child: userData!['ProfileImage'] == null
                    ? Icon(Icons.person, size: 60)
                    : null,
              ),
              SizedBox(height: 20),

              // ข้อมูลผู้ใช้
              if (!isEditing)
                Column(
                  children: [
                    Text('ชื่อ-นามสกุล: ${userData!['name']}', style: TextStyle(fontSize: 20)),
                    SizedBox(height: 10),
                    Text('อีเมล: ${userData!['email']}', style: TextStyle(fontSize: 18)),
                    SizedBox(height: 10),
                    Text('เบอร์โทร: ${userData!['phone']}', style: TextStyle(fontSize: 18)),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          isEditing = true;
                        });
                      },
                      child: Text('แก้ไขโปรไฟล์'),
                    ),
                    // ปุ่มออกจากระบบ
                    ElevatedButton(
                      onPressed: logout,
                      child: Text('ออกจากระบบ'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent, // สีของปุ่ม
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    ),
                  ],
                ),
              if (isEditing)
                Column(
                  children: [
                    // ฟอร์มสำหรับแก้ไขข้อมูล
                    TextField(
                      controller: fullNameController,
                      decoration: InputDecoration(labelText: 'ชื่อ-นามสกุล'),
                    ),
                    SizedBox(height: 10),
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: InputDecoration(labelText: 'รหัสผ่านใหม่'),
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: saveChanges,
                      child: Text('บันทึกการเปลี่ยนแปลง'),
                    ),
                    SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          isEditing = false;
                        });
                      },
                      child: Text('ยกเลิก'),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
