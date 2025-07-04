// lib/Screen/AdminScreen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:run_android/Admin/AdminSettingsScreen.dart';
import 'package:run_android/Admin/UserManagementScreen.dart';



class AdminScreen extends StatefulWidget {
  @override
  _AdminScreenState createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  int _selectedIndex = 0;

  // กำหนดสี Google Blue และสีแดงสำหรับ Admin (ถ้าคุณกำหนดไว้ใน main.dart แล้ว ไม่ต้องประกาศซ้ำ)
  // หากต้องการให้ Admin มีสีแดงเฉพาะตัว ควรประกาศใน class นี้ หรือส่งผ่าน Theme
  static const Color googleBlue = Color(0xFF4285F4);
  static const Color adminRed = Color(0xFFD32F2F); // สีแดงเข้มขึ้น
  static const Color googleLightBlueBackground = Color(0xFFE8F0FE);

  // รายการ Widget ที่จะแสดงในแต่ละ tab ของ BottomNavigationBar
  static final List<Widget> _widgetOptions = <Widget>[
    UserManagementScreen(), // หน้าจัดการผู้ใช้ (ต้องดึงข้อมูลผู้ใช้ในคลาสนี้)
    AdminSettingsScreen(), // หน้าตั้งค่าผู้ดูแลระบบ (ต้องดึง/จัดการข้อมูลในคลาสนี้)
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // พื้นหลังของ Scaffold จะเป็นสี googleLightBlueBackground ที่กำหนดใน main.dart
      appBar: AppBar(
        title: Text(
          'หน้าสำหรับผู้ดูแลระบบ',
          style: GoogleFonts.prompt(fontWeight: FontWeight.w600, color: Colors.white), // ใช้ Prompt
        ),
        backgroundColor: adminRed, // AppBar ของ Admin จะเป็นสีแดงเฉพาะตัว
        centerTitle: true,
        actions: [
          
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
        selectedItemColor: adminRed, // สีไอคอนที่เลือกเป็นสีแดง
        unselectedItemColor: Colors.grey, // สีไอคอนที่ยังไม่เลือก
        onTap: _onItemTapped,
        backgroundColor: Theme.of(context).colorScheme.surface, // ใช้สี surface ของ Theme (มักจะเป็นสีขาว)
        selectedLabelStyle: GoogleFonts.prompt(), // ฟอนต์สำหรับ label ที่เลือก
        unselectedLabelStyle: GoogleFonts.prompt(), // ฟอนต์สำหรับ label ที่ยังไม่เลือก
      ),
    );
  }
}