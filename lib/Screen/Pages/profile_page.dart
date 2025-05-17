import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:run_android/Screen/Pages/EditProfile/ChangePasswordPage.dart';
import 'package:run_android/Screen/Pages/EditProfile/EditProfilePage.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? userData;
  bool isLoading = true;
  bool notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        setState(() {
          userData = doc.data();
          isLoading = false;
        });
      }
    }
  }

  void logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushReplacementNamed('/login');
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return Scaffold(body: Center(child: CircularProgressIndicator()));
    if (userData == null) return Scaffold(body: Center(child: Text('ไม่พบข้อมูลผู้ใช้')));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'โปรไฟล์',
          style: GoogleFonts.kanit(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 60,
              backgroundImage: userData!['ProfileImage'] != null
                  ? NetworkImage(userData!['ProfileImage'])
                  : null,
              child: userData!['ProfileImage'] == null
                  ? Icon(Icons.person, size: 60, color: Colors.grey)
                  : null,
            ),
            SizedBox(height: 16),
            Text(
              userData!['FullName'] ?? '',
              style: GoogleFonts.kanit(fontSize: 22, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),
            Text(
              userData!['Email'] ?? '',
              style: GoogleFonts.kanit(fontSize: 16, color: Colors.grey[700]),
            ),
            SizedBox(height: 32),

            _buildButton(
              icon: Icons.edit,
              label: 'แก้ไขโปรไฟล์',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => EditProfilePage(userData: userData!)),
                ).then((_) => fetchUserData());
              },
            ),

            _buildButton(
              icon: Icons.lock,
              label: 'เปลี่ยนรหัสผ่าน',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ChangePasswordPage()),
                );
              },
            ),

            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                'ปิดการแจ้งเตือน',
                style: GoogleFonts.kanit(fontSize: 16),
              ),
              value: !notificationsEnabled,
              onChanged: (value) {
                setState(() => notificationsEnabled = !value);
              },
              secondary: Icon(Icons.notifications_off),
            ),

            SizedBox(height: 16),

            ElevatedButton.icon(
              icon: Icon(Icons.logout),
              label: Text(
                'ออกจากระบบ',
                style: GoogleFonts.kanit(fontWeight: FontWeight.bold),
              ),
              onPressed: logout,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ElevatedButton.icon(
        icon: Icon(icon),
        label: Text(
          label,
          style: GoogleFonts.kanit(fontSize: 16),
        ),
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          minimumSize: Size(double.infinity, 50),
          padding: EdgeInsets.symmetric(horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
