import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
// ตรวจสอบว่า path ไปยังหน้า EditProfilePage และ ChangePasswordPage ถูกต้อง
import 'package:run_android/Screen/Pages/EditProfile/ChangePasswordPage.dart';
import 'package:run_android/Screen/Pages/EditProfile/EditProfilePage.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  bool _notificationsEnabled = true; // ค่าเริ่มต้นของการแจ้งเตือน (สามารถดึงมาจาก Firestore ได้)

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (mounted) {
          if (doc.exists) {
            setState(() {
              _userData = doc.data();
              // ตัวอย่าง: หากคุณเก็บสถานะการแจ้งเตือนใน Firestore
              // _notificationsEnabled = _userData?['notificationsEnabled'] ?? true;
              _isLoading = false;
            });
          } else {
            setState(() {
              _userData = null;
              _isLoading = false;
            });
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'ไม่สามารถโหลดข้อมูลผู้ใช้ได้: $e',
                style: GoogleFonts.prompt(), // ใช้ Prompt
              ),
            ),
          );
        }
        print("Error fetching user data: $e");
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
          // ควรจัดการกรณีที่ไม่มีผู้ใช้ login อยู่
        });
      }
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      // ใช้ pushReplacementNamed เพื่อไม่ให้ผู้ใช้กดปุ่มย้อนกลับมาหน้านี้ได้
      Navigator.of(context).pushReplacementNamed('/login');
      // หรือหากต้องการล้าง stack ทั้งหมด:
      // Navigator.of(context).pushNamedAndRemoveUntil('/login', (Route<dynamic> route) => false);
    }
  }

  Widget _buildProfileActionItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return Card(
      elevation: 2.0,
      margin: const EdgeInsets.symmetric(vertical: 7.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: ListTile(
        leading: Icon(icon, color: iconColor ?? Theme.of(context).primaryColor, size: 24), // ใช้ primaryColor จากธีม
        title: Text(title, style: GoogleFonts.prompt(fontSize: 16)), // ใช้ Prompt
        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[600]),
        onTap: onTap,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  Widget _buildNotificationToggle() {
    return Card(
      elevation: 2.0,
      margin: const EdgeInsets.symmetric(vertical: 7.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: SwitchListTile(
        title: Text(
          'การแจ้งเตือน',
          style: GoogleFonts.prompt(fontSize: 16), // ใช้ Prompt
        ),
        value: _notificationsEnabled,
        onChanged: (bool value) {
          setState(() {
            _notificationsEnabled = value;
            // TODO: บันทึกค่า _notificationsEnabled นี้ (เช่น ลง Firestore หรือ SharedPreferences)
            // ตัวอย่าง:
            // if (FirebaseAuth.instance.currentUser != null) {
            //   FirebaseFirestore.instance
            //       .collection('users')
            //       .doc(FirebaseAuth.instance.currentUser!.uid)
            //       .update({'notificationsEnabled': value});
            // }
          });
        },
        secondary: Icon(
          _notificationsEnabled ? Icons.notifications_active_outlined : Icons.notifications_off_outlined,
          color: Theme.of(context).primaryColor, // ใช้ primaryColor จากธีม
          size: 24,
        ),
        activeColor: Theme.of(context).primaryColor, // สีของ Switch เมื่อเปิด
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Scaffold background color และ AppBar theme จะถูกใช้จาก main.dart โดยอัตโนมัติ

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('โปรไฟล์', style: GoogleFonts.prompt(fontWeight: FontWeight.bold)), // ใช้ Prompt
          centerTitle: true,
        ),
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor), 
          ),
        ),
      );
    }

    if (_userData == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('โปรไฟล์', style: GoogleFonts.prompt(fontWeight: FontWeight.bold)), // ใช้ Prompt
          centerTitle: true,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, color: Colors.red, size: 50),
                SizedBox(height: 16),
                Text('ไม่พบข้อมูลผู้ใช้', style: GoogleFonts.prompt(fontSize: 18, color: Colors.red)), // ใช้ Prompt
                SizedBox(height: 20),
                ElevatedButton.icon(
                  icon: Icon(Icons.refresh),
                  label: Text(
                    'ลองอีกครั้ง',
                    // Text style จะถูกกำหนดโดย ElevatedButtonTheme ใน main.dart
                  ),
                  onPressed: _fetchUserData,
                  style: ElevatedButton.styleFrom(
                    // ไม่ต้องกำหนด backgroundColor, foregroundColor, shape, minimumSize, textStyle ที่นี่
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12), // สามารถปรับ padding ได้
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    String? profileImageUrl = _userData!['ProfileImage'] as String?;
    bool hasProfileImage = profileImageUrl != null && profileImageUrl.isNotEmpty;
    String fullName = _userData!['FullName'] ?? 'ไม่พบชื่อ';
    String email = _userData!['Email'] ?? 'ไม่พบอีเมล';

    return Scaffold(
      appBar: AppBar(
        title: Text('โปรไฟล์', style: GoogleFonts.prompt(fontWeight: FontWeight.bold)), // ใช้ Prompt
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 20),
            CircleAvatar(
              radius: 60,
              backgroundColor: Colors.grey.shade300,
              backgroundImage: hasProfileImage ? NetworkImage(profileImageUrl!) : null,
              child: !hasProfileImage
                  ? Icon(Icons.person, size: 60, color: Colors.grey.shade700)
                  : null,
            ),
            SizedBox(height: 16),
            Text(
              fullName,
              style: GoogleFonts.prompt(fontSize: 22, fontWeight: FontWeight.w600), // ใช้ Prompt
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              email,
              style: GoogleFonts.prompt(fontSize: 16, color: Colors.grey[700]), // ใช้ Prompt
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32),

            _buildProfileActionItem(
              icon: Icons.edit_outlined,
              title: 'แก้ไขโปรไฟล์',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => EditProfilePage(userData: _userData!)),
                ).then((result) {
                  // รีเฟรชข้อมูลหลังจากแก้ไข หากมีการเปลี่ยนแปลง
                  if (result == true && mounted) {
                    _fetchUserData();
                  }
                });
              },
            ),

            _buildProfileActionItem(
              icon: Icons.lock_outline,
              title: 'เปลี่ยนรหัสผ่าน',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ChangePasswordPage()),
                );
              },
            ),

            _buildNotificationToggle(),

            SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: Icon(Icons.logout), // สีไอคอนจะถูกกำหนดโดย foregroundColor ของปุ่ม
                label: Text(
                  'ออกจากระบบ',
                  style: GoogleFonts.prompt(fontWeight: FontWeight.bold, fontSize: 16), // ใช้ Prompt
                ),
                onPressed: _logout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent, // ปุ่ม Logout มีสีแดงเป็นพิเศษ
                  foregroundColor: Colors.white, // ข้อความเป็นสีขาว
                  padding: EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                  elevation: 2.0,
                ),
              ),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}