import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cool_alert/cool_alert.dart';
// ตรวจสอบว่า path ไปยังหน้า EditProfilePage และ ChangePasswordPage ถูกต้อง
import 'package:run_android/Screen/Pages/EditProfile/ChangePasswordPage.dart';
import 'package:run_android/Screen/Pages/EditProfile/EditProfilePage.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with TickerProviderStateMixin {
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  bool _notificationsEnabled = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic));
    
    _fetchUserData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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
              _isLoading = false;
            });
            _animationController.forward();
          } else {
            setState(() {
              _userData = null;
              _isLoading = false;
            });
            _showErrorAlert('ไม่พบข้อมูลผู้ใช้', 'กรุณาลองใหม่อีกครั้ง');
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          _showErrorAlert('เกิดข้อผิดพลาด', 'ไม่สามารถโหลดข้อมูลผู้ใช้ได้: $e');
        }
        print("Error fetching user data: $e");
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorAlert('ไม่พบผู้ใช้', 'กรุณาเข้าสู่ระบบใหม่');
      }
    }
  }

  void _showErrorAlert(String title, String message) {
    CoolAlert.show(
      context: context,
      type: CoolAlertType.error,
      title: title,
      text: message,
      confirmBtnText: 'ตกลง',
      confirmBtnColor: Colors.redAccent,
      backgroundColor: Colors.white,
      titleTextStyle: GoogleFonts.prompt(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.red,
      ),
      textTextStyle: GoogleFonts.prompt(
        fontSize: 16,
        color: Colors.grey[700],
      ),
      confirmBtnTextStyle: GoogleFonts.prompt(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }

  void _showSuccessAlert(String title, String message) {
    CoolAlert.show(
      context: context,
      type: CoolAlertType.success,
      title: title,
      text: message,
      confirmBtnText: 'ตกลง',
      confirmBtnColor: Theme.of(context).primaryColor,
      backgroundColor: Colors.white,
      titleTextStyle: GoogleFonts.prompt(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.green,
      ),
      textTextStyle: GoogleFonts.prompt(
        fontSize: 16,
        color: Colors.grey[700],
      ),
      confirmBtnTextStyle: GoogleFonts.prompt(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }

  Future<void> _logout() async {
    CoolAlert.show(
      context: context,
      type: CoolAlertType.confirm,
      title: 'ออกจากระบบ',
      text: 'คุณต้องการออกจากระบบหรือไม่?',
      confirmBtnText: 'ออกจากระบบ',
      cancelBtnText: 'ยกเลิก',
      confirmBtnColor: Colors.redAccent,
      backgroundColor: Colors.white,
      titleTextStyle: GoogleFonts.prompt(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.orange,
      ),
      textTextStyle: GoogleFonts.prompt(
        fontSize: 16,
        color: Colors.grey[700],
      ),
      confirmBtnTextStyle: GoogleFonts.prompt(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      cancelBtnTextStyle: GoogleFonts.prompt(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.grey[700],
      ),
      onConfirmBtnTap: () async {
        Navigator.of(context).pop();
        
        // แสดง Loading
        CoolAlert.show(
          context: context,
          type: CoolAlertType.loading,
          title: 'กำลังออกจากระบบ...',
          text: 'กรุณารอสักครู่',
          backgroundColor: Colors.white,
          titleTextStyle: GoogleFonts.prompt(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
          textTextStyle: GoogleFonts.prompt(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        );

        try {
          await FirebaseAuth.instance.signOut();
          Navigator.of(context).pop(); // ปิด Loading dialog
          
          if (mounted) {
            Navigator.of(context).pushReplacementNamed('/login');
          }
        } catch (e) {
          Navigator.of(context).pop(); // ปิด Loading dialog
          _showErrorAlert('เกิดข้อผิดพลาด', 'ไม่สามารถออกจากระบบได้: $e');
        }
      },
    );
  }

  Widget _buildProfileActionItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
    Color? backgroundColor,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Material(
        elevation: 4.0,
        shadowColor: Colors.black.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16.0),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.0),
            gradient: LinearGradient(
              colors: backgroundColor != null 
                ? [backgroundColor, backgroundColor.withOpacity(0.8)]
                : [Colors.white, Colors.grey.shade50],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: ListTile(
            leading: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (iconColor ?? Theme.of(context).primaryColor).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon, 
                color: iconColor ?? Theme.of(context).primaryColor, 
                size: 24,
              ),
            ),
            title: Text(
              title, 
              style: GoogleFonts.prompt(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: backgroundColor != null ? Colors.white : Colors.grey[800],
              ),
            ),
            trailing: Icon(
              Icons.arrow_forward_ios, 
              size: 16, 
              color: backgroundColor != null ? Colors.white70 : Colors.grey[600],
            ),
            onTap: onTap,
            contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationToggle() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Material(
        elevation: 4.0,
        shadowColor: Colors.black.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16.0),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.0),
            gradient: LinearGradient(
              colors: [Colors.white, Colors.grey.shade50],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SwitchListTile(
            title: Text(
              'การแจ้งเตือน',
              style: GoogleFonts.prompt(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            subtitle: Text(
              _notificationsEnabled ? 'เปิดการแจ้งเตือน' : 'ปิดการแจ้งเตือน',
              style: GoogleFonts.prompt(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            value: _notificationsEnabled,
            onChanged: (bool value) {
              setState(() {
                _notificationsEnabled = value;
              });
              
              // แสดง Cool Alert เมื่อเปลี่ยนสถานะ
              CoolAlert.show(
                context: context,
                type: CoolAlertType.info,
                title: 'อัปเดตการแจ้งเตือน',
                text: value ? 'เปิดการแจ้งเตือนเรียบร้อย' : 'ปิดการแจ้งเตือนเรียบร้อย',
                confirmBtnText: 'ตกลง',
                confirmBtnColor: Theme.of(context).primaryColor,
                backgroundColor: Colors.white,
                titleTextStyle: GoogleFonts.prompt(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
                textTextStyle: GoogleFonts.prompt(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
                confirmBtnTextStyle: GoogleFonts.prompt(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                autoCloseDuration: Duration(seconds: 2),
              );
            },
            secondary: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _notificationsEnabled ? Icons.notifications_active : Icons.notifications_off,
                color: Theme.of(context).primaryColor,
                size: 24,
              ),
            ),
            activeColor: Theme.of(context).primaryColor,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    String? profileImageUrl = _userData!['ProfileImage'] as String?;
    bool hasProfileImage = profileImageUrl != null && profileImageUrl.isNotEmpty;
    String fullName = _userData!['FullName'] ?? 'ไม่พบชื่อ';
    String email = _userData!['Email'] ?? 'ไม่พบอีเมล';

    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withOpacity(0.3),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 65,
                  backgroundColor: Colors.white,
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage: hasProfileImage ? NetworkImage(profileImageUrl!) : null,
                    child: !hasProfileImage
                        ? Icon(Icons.person, size: 60, color: Colors.grey.shade600)
                        : null,
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          Text(
            fullName,
            style: GoogleFonts.prompt(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              email,
              style: GoogleFonts.prompt(
                fontSize: 16,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).primaryColor.withOpacity(0.1),
                Colors.white,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
                  strokeWidth: 3,
                ),
                SizedBox(height: 20),
                Text(
                  'กำลังโหลดข้อมูล...',
                  style: GoogleFonts.prompt(
                    fontSize: 16,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_userData == null) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).primaryColor.withOpacity(0.1),
                Colors.white,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.error_outline, color: Colors.red, size: 50),
                  ),
                  SizedBox(height: 24),
                  Text(
                    'ไม่พบข้อมูลผู้ใช้',
                    style: GoogleFonts.prompt(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'กรุณาลองใหม่อีกครั้ง',
                    style: GoogleFonts.prompt(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 32),
                  ElevatedButton.icon(
                    icon: Icon(Icons.refresh),
                    label: Text(
                      'ลองอีกครั้ง',
                      style: GoogleFonts.prompt(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: _fetchUserData,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).primaryColor.withOpacity(0.1),
              Colors.white,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // App Bar
                    Container(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: Icon(Icons.arrow_back_ios),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                          Text(
                            'โปรไฟล์',
                            style: GoogleFonts.prompt(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.settings),
                            onPressed: () {
                              CoolAlert.show(
                                context: context,
                                type: CoolAlertType.info,
                                title: 'การตั้งค่า',
                                text: 'ฟีเจอร์นี้จะเปิดให้ใช้งานเร็วๆ นี้',
                                confirmBtnText: 'ตกลง',
                                confirmBtnColor: Theme.of(context).primaryColor,
                                backgroundColor: Colors.white,
                                titleTextStyle: GoogleFonts.prompt(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: const Color.fromARGB(255, 248, 249, 250),
                                ),
                                textTextStyle: GoogleFonts.prompt(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                ),
                                confirmBtnTextStyle: GoogleFonts.prompt(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                autoCloseDuration: Duration(seconds: 2),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    
                    SizedBox(height: 20),
                    
                    // Profile Header
                    _buildProfileHeader(),
                    
                    SizedBox(height: 32),

                    // Profile Actions
                    _buildProfileActionItem(
                      icon: Icons.edit_outlined,
                      title: 'แก้ไขโปรไฟล์',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => EditProfilePage(userData: _userData!)),
                        ).then((result) {
                          if (result == true && mounted) {
                            _fetchUserData();
                            _showSuccessAlert('อัปเดตข้อมูล', 'ข้อมูลโปรไฟล์ถูกอัปเดตเรียบร้อย');
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
                        ).then((result) {
                          if (result == true && mounted) {
                            _showSuccessAlert('เปลี่ยนรหัสผ่าน', 'รหัสผ่านถูกเปลี่ยนเรียบร้อย');
                          }
                        });
                      },
                    ),

                    _buildNotificationToggle(),

                    _buildProfileActionItem(
                      icon: Icons.help_outline,
                      title: 'ช่วยเหลือ',
                      onTap: () {
                        CoolAlert.show(
                          context: context,
                          type: CoolAlertType.info,
                          title: 'ช่วยเหลือ',
                          text: 'หากต้องการความช่วยเหลือ กรุณาติดต่อทีมงาน',
                          confirmBtnText: 'ตกลง',
                          confirmBtnColor: Theme.of(context).primaryColor,
                          backgroundColor: Colors.white,
                          titleTextStyle: GoogleFonts.prompt(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                          textTextStyle: GoogleFonts.prompt(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                          confirmBtnTextStyle: GoogleFonts.prompt(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        );
                      },
                    ),

                    SizedBox(height: 24),

                    // Logout Button
                    SizedBox(
                      width: double.infinity,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.redAccent, Colors.red],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.redAccent.withOpacity(0.3),
                              blurRadius: 10,
                              offset: Offset(0, 5),
                            ),
                          ],
                        ),
                        child: ElevatedButton.icon(
                          icon: Icon(Icons.logout, color: Colors.white),
                          label: Text(
                            'ออกจากระบบ',
                            style: GoogleFonts.prompt(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                          onPressed: _logout,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}