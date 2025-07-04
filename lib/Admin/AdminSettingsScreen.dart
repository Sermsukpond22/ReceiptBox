import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:run_android/Admin/ChangPasswordScreen.dart';
import 'package:run_android/Screen/LoginScreen.dart';
import 'package:cool_alert/cool_alert.dart';

class AdminSettingsScreen extends StatefulWidget {
  @override
  _AdminSettingsScreenState createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  User? _currentUser;
  String? _profileImageUrl;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    _currentUser = FirebaseAuth.instance.currentUser;
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _logout() async {
    CoolAlert.show(
      context: context,
      type: CoolAlertType.confirm,
      title: "ออกจากระบบ",
      text: "คุณแน่ใจหรือไม่ว่าต้องการออกจากระบบ?",
      confirmBtnText: "ใช่",
      cancelBtnText: "ยกเลิก",
      onConfirmBtnTap: () async {
        await FirebaseAuth.instance.signOut();
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => LoginScreen()),
          (route) => false,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('ตั้งค่าผู้ดูแลระบบ', style: GoogleFonts.prompt()),
        backgroundColor: Colors.grey,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            CircleAvatar(
              radius: 55,
              backgroundColor: Colors.white,
              backgroundImage: _profileImageUrl != null
                  ? NetworkImage(_profileImageUrl!)
                  : AssetImage('assets/images/default_profile.png') as ImageProvider,
            ),
            SizedBox(height: 20),
            Text(
              _currentUser?.email ?? 'ไม่พบอีเมล',
              style: GoogleFonts.prompt(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 30),
            ListTile(
              leading: Icon(Icons.lock_outline, color: Colors.blueAccent),
              title: Text('เปลี่ยนรหัสผ่าน', style: GoogleFonts.prompt(fontSize: 16)),
              trailing: Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ChangePasswordScreen()),
                );
              },
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.exit_to_app, color: Colors.redAccent),
              title: Text('ออกจากระบบ', style: GoogleFonts.prompt(fontSize: 16, color: Colors.red)),
              onTap: _logout,
            ),
          ],
        ),
      ),
    );
  }
}
