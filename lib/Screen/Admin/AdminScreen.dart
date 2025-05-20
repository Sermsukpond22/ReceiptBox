// lib/Screen/AdminScreen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart'; // สำหรับ logout
// import 'package:cloud_firestore/cloud_firestore.dart'; // สำหรับใช้ในอนาคตถ้าต้องการ
import 'package:cool_alert/cool_alert.dart'; // สำหรับแจ้งเตือน
import 'package:run_android/Screen/LoginScreen.dart';

import 'UserManagementScreen.dart'; // import หน้าจัดการผู้ใช้
import 'AdminSettingsScreen.dart'; // import หน้าตั้งค่าผู้ดูแลระบบ


class AdminScreen extends StatefulWidget {
  @override
  _AdminScreenState createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  int _selectedIndex = 0;

  // รายการ Widget ที่จะแสดงในแต่ละ tab ของ BottomNavigationBar
  static final List<Widget> _widgetOptions = <Widget>[
    UserManagementScreen(), // หน้าจัดการผู้ใช้
    AdminSettingsScreen(), // หน้าตั้งค่าผู้ดูแลระบบ
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // ฟังก์ชันสำหรับออกจากระบบ
  Future<void> _logout() async {
    CoolAlert.show(
      context: context,
      type: CoolAlertType.confirm,
      title: 'ออกจากระบบ',
      text: 'คุณแน่ใจหรือไม่ที่ต้องการออกจากระบบ?',
      confirmBtnText: 'ใช่',
      cancelBtnText: 'ไม่',
      onConfirmBtnTap: () async {
        try {
          await FirebaseAuth.instance.signOut();
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => LoginScreen()),
            (Route<dynamic> route) => false, // ลบทุกหน้าออกจาก stack
          );
          CoolAlert.show(
            context: context,
            type: CoolAlertType.success,
            title: 'ออกจากระบบสำเร็จ',
            text: 'กำลังนำคุณไปยังหน้าเข้าสู่ระบบ',
            autoCloseDuration: Duration(seconds: 2),
          );
        } catch (e) {
          CoolAlert.show(
            context: context,
            type: CoolAlertType.error,
            title: 'เกิดข้อผิดพลาด',
            text: 'ไม่สามารถออกจากระบบได้: ${e.toString()}',
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'หน้าสำหรับผู้ดูแลระบบ',
          style: GoogleFonts.prompt(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        backgroundColor: Colors.red[700],
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: Colors.white),
            onPressed: _logout,
            tooltip: 'ออกจากระบบ',
          ),
        ],
      ),
      body: _widgetOptions.elementAt(_selectedIndex), // แสดง Widget ตามเมนูที่เลือก
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'จัดการผู้ใช้',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'ตั้งค่าผู้ดูแลระบบ',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.red[700], // สีไอคอนที่เลือก
        unselectedItemColor: Colors.grey, // สีไอคอนที่ยังไม่เลือก
        onTap: _onItemTapped,
        backgroundColor: Colors.white,
        selectedLabelStyle: GoogleFonts.prompt(),
        unselectedLabelStyle: GoogleFonts.prompt(),
      ),
    );
  }
}