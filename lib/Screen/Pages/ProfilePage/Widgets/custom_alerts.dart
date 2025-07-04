// lib/utils/custom_alerts.dart
import 'package:flutter/material.dart';
import 'package:cool_alert/cool_alert.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomAlerts {
  static void showErrorAlert(BuildContext context, String title, String message) {
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

  static void showSuccessAlert(BuildContext context, String title, String message) {
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

  static Future<bool?> showConfirmAlert(BuildContext context, String title, String message, String confirmText, {Color? confirmColor}) async {
    return await CoolAlert.show(
      context: context,
      type: CoolAlertType.confirm,
      title: title,
      text: message,
      confirmBtnText: confirmText,
      cancelBtnText: 'ยกเลิก',
      confirmBtnColor: confirmColor ?? Theme.of(context).primaryColor,
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
      onConfirmBtnTap: () {
        Navigator.of(context).pop(true);
      },
      onCancelBtnTap: () {
        Navigator.of(context).pop(false);
      },
    );
  }

  static void showLoadingAlert(BuildContext context, String title, String message) {
    CoolAlert.show(
      context: context,
      type: CoolAlertType.loading,
      title: title,
      text: message,
      barrierDismissible: false, // Prevent dismissal by tapping outside
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
  }
}