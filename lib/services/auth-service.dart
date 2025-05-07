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

  @override
  void dispose() {
    // เพิ่มการจัดการ resource หรือการยกเลิกการทำงานที่เกี่ยวข้องในที่นี้หากมี
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (userData == null) {
      return Center(child: Text('ไม่พบข้อมูลผู้ใช้'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
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
          Text('ชื่อ-นามสกุล: ${userData!['FullName']}', style: TextStyle(fontSize: 20)),
          SizedBox(height: 10),
          Text('อีเมล: ${userData!['Email']}', style: TextStyle(fontSize: 18)),
          SizedBox(height: 10),
          Text('เบอร์โทร: ${userData!['PhoneNumber']}', style: TextStyle(fontSize: 18)),
          SizedBox(height: 10),

          // ปุ่ม Logout
          ElevatedButton.icon(
            onPressed: logout,
            icon: Icon(Icons.logout),
            label: Text('ออกจากระบบ'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          )
        ],
      ),
    );
  }
}
