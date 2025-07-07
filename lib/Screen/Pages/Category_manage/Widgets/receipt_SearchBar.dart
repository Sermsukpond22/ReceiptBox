import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CategorySearchBar extends StatelessWidget {
  final Function(String) onChanged;
  final TextEditingController controller; // ✨ เปลี่ยนมาใช้ Controller ที่ส่งมาจาก Parent
  final VoidCallback onClear;

  const CategorySearchBar({
    Key? key,
    required this.onChanged,
    required this.controller,
    required this.onClear,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8), // ปรับระยะห่าง
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30), // ทำให้มนขึ้น
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          controller: controller, // ✨ ใช้ Controller จาก Parent
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: 'ค้นหาจากชื่อใบเสร็จ...',
            hintStyle: GoogleFonts.prompt(color: Colors.grey[500]),
            prefixIcon: const Icon(Icons.search, color: Colors.grey),
            // ✨ ปรับปรุงการแสดงปุ่ม clear
            suffixIcon: controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.grey),
                    onPressed: onClear,
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          ),
          style: GoogleFonts.prompt(fontSize: 16, color: Colors.black87),
        ),
      ),
    );
  }
}