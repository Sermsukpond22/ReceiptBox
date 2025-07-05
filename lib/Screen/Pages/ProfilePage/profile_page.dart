// lib/screens/profile_page/profile_page.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:run_android/Screen/LoginScreen.dart';
import 'package:run_android/Screen/Pages/ProfilePage/Widgets/custom_alerts.dart';
import 'package:run_android/Screen/Pages/ProfilePage/Widgets/notification_toggle.dart';
import 'package:run_android/Screen/Pages/ProfilePage/Widgets/profile_action_item.dart';
import 'package:run_android/Screen/Pages/ProfilePage/Widgets/profile_header.dart';

// ตรวจสอบว่า path ไปยังหน้า EditProfilePage และ ChangePasswordPage ถูกต้อง
import 'package:run_android/Screen/Pages/ProfilePage/EditProfile/ChangePasswordPage.dart';
import 'package:run_android/Screen/Pages/ProfilePage/EditProfile/EditProfilePage.dart';
import 'package:run_android/services/auth-service.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with TickerProviderStateMixin {
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
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

    final user = AuthService.currentUser; // ใช้ AuthService.currentUser
    if (user != null) {
      try {
        final data = await AuthService.getCurrentUserData(); // ใช้ AuthService.getCurrentUserData()
        if (mounted) {
          if (data != null) {
            setState(() {
              _userData = data;
              _isLoading = false;
            });
            _animationController.forward();
          } else {
            setState(() {
              _userData = null;
              _isLoading = false;
            });
            // ตรวจสอบว่า context ยังคงใช้ได้ก่อนแสดง Alert
            if (mounted) {
               CustomAlerts.showErrorAlert(context, 'ไม่พบข้อมูลผู้ใช้', 'กรุณาลองใหม่อีกครั้ง');
            }
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          // ตรวจสอบว่า context ยังคงใช้ได้ก่อนแสดง Alert
          if (mounted) {
            CustomAlerts.showErrorAlert(context, 'เกิดข้อผิดพลาด', 'ไม่สามารถโหลดข้อมูลผู้ใช้ได้: $e');
          }
        }
        print("Error fetching user data: $e");
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        // ตรวจสอบว่า context ยังคงใช้ได้ก่อนแสดง Alert
        if (mounted) {
          CustomAlerts.showErrorAlert(context, 'ไม่พบผู้ใช้', 'กรุณาเข้าสู่ระบบใหม่');
        }
      }
    }
  }

   Future<void> _logout() async {
    final bool? confirm = await CustomAlerts.showConfirmAlert(
      context,
      'ออกจากระบบ',
      'คุณต้องการออกจากระบบหรือไม่?',
      'ออกจากระบบ',
      confirmColor: Colors.redAccent,
    );

    if (confirm == true) {
      if (!mounted) return; 
      CustomAlerts.showLoadingAlert(context, 'กำลังออกจากระบบ...', 'กรุณารอสักครู่');
      
      try {
        await AuthService.logout(); 
        
        if (mounted) {
          // ปิด dialog โหลด
          Navigator.of(context).pop(); 

          // กำหนดให้การนำทางเกิดขึ้นหลังจาก build ของเฟรมถัดไปเสร็จสิ้น
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) { 
              // *** เปลี่ยนมาใช้ pushAndRemoveUntil เพื่อเคลียร์ stack ทั้งหมด ***
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => LoginScreen()), // เปลี่ยน LoginPage() ตามชื่อหน้า Login ของคุณ
                (Route<dynamic> route) => false, // เงื่อนไขนี้หมายถึง ลบทุก route จนหมด
              );
            }
          });
        }
      } catch (e) {
        if (mounted) {
          Navigator.of(context).pop(); 
          CustomAlerts.showErrorAlert(context, 'เกิดข้อผิดพลาด', 'ไม่สามารถออกจากระบบได้: $e');
        }
      }
    }
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
                const SizedBox(height: 20),
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
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.error_outline, color: Colors.red, size: 50),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'ไม่พบข้อมูลผู้ใช้',
                    style: GoogleFonts.prompt(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'กรุณาลองใหม่อีกครั้ง',
                    style: GoogleFonts.prompt(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: Text(
                      'ลองอีกครั้ง',
                      style: GoogleFonts.prompt(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: _fetchUserData,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
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
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_ios),
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
                            icon: const Icon(Icons.settings),
                            onPressed: () {
                              CustomAlerts.showSuccessAlert(
                                context,
                                'การตั้งค่า',
                                'ฟีเจอร์นี้จะเปิดให้ใช้งานเร็วๆ นี้',
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Profile Header
                    ProfileHeader(userData: _userData!),

                    const SizedBox(height: 32),

                    // Profile Actions
                    ProfileActionItem(
                      icon: Icons.edit_outlined,
                      title: 'แก้ไขโปรไฟล์',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => EditProfilePage(userData: _userData!)),
                        ).then((result) {
                          if (result == true && mounted) {
                            _fetchUserData(); // Refresh data after editing
                            CustomAlerts.showSuccessAlert(context, 'อัปเดตข้อมูล', 'ข้อมูลโปรไฟล์ถูกอัปเดตเรียบร้อย');
                          }
                        });
                      },
                    ),

                    ProfileActionItem(
                      icon: Icons.lock_outline,
                      title: 'เปลี่ยนรหัสผ่าน',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => ChangePasswordPage()),
                        ).then((result) {
                          if (result == true && mounted) {
                            CustomAlerts.showSuccessAlert(context, 'เปลี่ยนรหัสผ่าน', 'รหัสผ่านถูกเปลี่ยนเรียบร้อย');
                          }
                        });
                      },
                    ),

                    const NotificationToggle(), // ใช้ NotificationToggle widget ที่แยกออกมา

                    ProfileActionItem(
                      icon: Icons.help_outline,
                      title: 'ช่วยเหลือ',
                      onTap: () {
                        CustomAlerts.showSuccessAlert(
                          context,
                          'ช่วยเหลือ',
                          'หากต้องการความช่วยเหลือ กรุณาติดต่อทีมงาน',
                        );
                      },
                    ),

                    const SizedBox(height: 24),

                    // Logout Button
                    SizedBox(
                      width: double.infinity,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Colors.redAccent, Colors.red],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.redAccent.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.logout, color: Colors.white),
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
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),
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