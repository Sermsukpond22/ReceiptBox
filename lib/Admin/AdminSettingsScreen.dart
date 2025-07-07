import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:run_android/Admin/ChangPasswordScreen.dart'; // Assuming this path is correct
import 'package:run_android/Screen/LoginScreen.dart'; // Assuming this path is correct
import 'package:cool_alert/cool_alert.dart';

class AdminSettingsScreen extends StatefulWidget {
  @override
  _AdminSettingsScreenState createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  User? _currentUser;
  String? _profileImageUrl; // This would typically be loaded from a service or storage

  @override
  void initState() {
    super.initState();
    _loadUserData();
    // You might want to load _profileImageUrl here as well, e.g., from Firestore or Storage
    // For demonstration, let's assume it's null and uses the default image.
  }

  Future<void> _loadUserData() async {
    _currentUser = FirebaseAuth.instance.currentUser;
    if (mounted) {
      setState(() {
        // Potentially load profile image URL here if available from user data
        // _profileImageUrl = _currentUser?.photoURL;
      });
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
      confirmBtnColor: Colors.redAccent, // Make confirm button stand out for logout
      onConfirmBtnTap: () async {
        await FirebaseAuth.instance.signOut();
        // Ensure that Navigator pops all routes and then pushes the new one.
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
      backgroundColor: Colors.white, // Use white as main background for cleaner look
      appBar: AppBar(
        title: Text('ตั้งค่าผู้ดูแลระบบ', style: GoogleFonts.prompt(
          fontWeight: FontWeight.w600, // Make app bar title bolder
          color: Colors.white, // Text color for app bar
        )),
        backgroundColor: Colors.indigo, // Use a more distinct color for the app bar
        elevation: 0, // No shadow for a modern flat design
        centerTitle: true, // Center the title for better aesthetics
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 30.0), // More symmetric padding
        child: Column(
          children: [
            // Profile Image Section
            CircleAvatar(
              radius: 60, // Slightly larger radius
              backgroundColor: Colors.grey[200], // Lighter background for avatar
              backgroundImage: _profileImageUrl != null
                  ? NetworkImage(_profileImageUrl!)
                  : const AssetImage('assets/images/default_profile.png') as ImageProvider,
              child: _profileImageUrl == null // Add an icon if no image is present
                  ? Icon(Icons.person, size: 60, color: Colors.grey[600])
                  : null,
            ),
            const SizedBox(height: 25), // Increased spacing

            // User Email Section
            Text(
              _currentUser?.email ?? 'ไม่พบอีเมล',
              textAlign: TextAlign.center,
              style: GoogleFonts.prompt(
                fontSize: 20, // Slightly larger font size
                fontWeight: FontWeight.w600, // Bolder font weight
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 40), // More spacing before options

            // Settings Options
            _buildSettingsTile(
              context,
              icon: Icons.lock_outline,
              title: 'เปลี่ยนรหัสผ่าน',
              color: Colors.blueAccent,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ChangePasswordScreen()),
                );
              },
            ),
            const Divider(height: 1, thickness: 1, indent: 20, endIndent: 20), // Thinner divider with indents
            _buildSettingsTile(
              context,
              icon: Icons.exit_to_app,
              title: 'ออกจากระบบ',
              color: Colors.redAccent,
              onTap: _logout,
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to build consistent settings tiles
  Widget _buildSettingsTile(BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 2, // Subtle shadow for card effect
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), // Rounded corners
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0), // More padding
        leading: Icon(icon, color: color, size: 28), // Larger icon size
        title: Text(
          title,
          style: GoogleFonts.prompt(
            fontSize: 17, // Consistent font size
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey), // Slightly larger arrow
        onTap: onTap,
      ),
    );
  }
}