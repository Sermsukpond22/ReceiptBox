// lib/widgets/receipt_image_section.dart

import 'dart:io';
import 'package:flutter/material.dart';

class ReceiptImageSection extends StatelessWidget {
  final File? imageFile;
  final VoidCallback onTap;

  const ReceiptImageSection({
    super.key,
    required this.imageFile,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: imageFile != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  imageFile!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              )
            : _buildImagePlaceholder(),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_a_photo, size: 50, color: Colors.grey[600]),
        const SizedBox(height: 8),
        Text('แตะเพื่อเลือกรูปภาพใบเสร็จ', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
        const SizedBox(height: 4),
        Text('(ไม่บังคับ)', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
      ],
    );
  }
}