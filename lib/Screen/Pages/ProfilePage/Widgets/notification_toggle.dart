// lib/screens/profile_page/widgets/notification_toggle.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:run_android/Screen/Pages/ProfilePage/Widgets/custom_alerts.dart';


class NotificationToggle extends StatefulWidget {
  const NotificationToggle({super.key});

  @override
  State<NotificationToggle> createState() => _NotificationToggleState();
}

class _NotificationToggleState extends State<NotificationToggle> {
  bool _notificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
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

              CustomAlerts.showSuccessAlert(
                context,
                'อัปเดตการแจ้งเตือน',
                value ? 'เปิดการแจ้งเตือนเรียบร้อย' : 'ปิดการแจ้งเตือนเรียบร้อย',
              );
              // ในอนาคตคุณอาจจะบันทึกสถานะนี้ลงใน Local Storage หรือ Firebase
            },
            secondary: Container(
              padding: const EdgeInsets.all(8),
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
}