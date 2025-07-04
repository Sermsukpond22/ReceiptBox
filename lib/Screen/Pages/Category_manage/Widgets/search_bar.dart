import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CategorySearchBar extends StatelessWidget {
  final Function(String) onChanged;
  final String searchQuery;
  final VoidCallback onClear;

  const CategorySearchBar({
    Key? key,
    required this.onChanged,
    required this.searchQuery,
    required this.onClear,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextField(
        controller: TextEditingController(text: searchQuery)..selection = TextSelection.collapsed(offset: searchQuery.length),
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: 'ค้นหาหมวดหมู่...',
          hintStyle: GoogleFonts.prompt(color: Colors.grey[600], fontSize: 16),
          prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
          suffixIcon: searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: Colors.grey[600]),
                  onPressed: onClear,
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
        style: GoogleFonts.prompt(fontSize: 16),
      ),
    );
  }
}