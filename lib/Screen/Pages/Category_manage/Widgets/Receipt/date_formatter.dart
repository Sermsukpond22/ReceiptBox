import 'package:intl/intl.dart';

String formatDateForGrouping(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = DateTime(now.year, now.month, now.day - 1);
  final dateToCompare = DateTime(date.year, date.month, date.day);

  if (dateToCompare == today) {
    return 'วันนี้';
  } else if (dateToCompare == yesterday) {
    return 'เมื่อวานนี้';
  } else {
    // ใช้ DateFormat สำหรับภาษาไทย
    return DateFormat('d MMMM yyyy', 'th').format(date);
  }
}