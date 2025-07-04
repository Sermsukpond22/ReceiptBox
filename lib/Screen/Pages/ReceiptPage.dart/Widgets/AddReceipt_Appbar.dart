// lib/widgets/add_receipt_app_bar.dart

import 'package:flutter/material.dart';

class AddReceiptAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool isActionDisabled;
  final VoidCallback onHelpPressed;
  final VoidCallback onImagePressed;
  final VoidCallback onClearPressed;

  const AddReceiptAppBar({
    super.key,
    required this.isActionDisabled,
    required this.onHelpPressed,
    required this.onImagePressed,
    required this.onClearPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text('เพิ่มใบเสร็จ'),
      backgroundColor: Theme.of(context).primaryColor,
      foregroundColor: Colors.white,
      elevation: 2,
      actions: [
        IconButton(
          icon: const Icon(Icons.help_outline),
          onPressed: onHelpPressed,
          tooltip: 'ช่วยเหลือ',
        ),
        IconButton(
          icon: const Icon(Icons.add_a_photo),
          onPressed: isActionDisabled ? null : onImagePressed,
          tooltip: 'เลือกรูปภาพ',
        ),
        IconButton(
          icon: const Icon(Icons.clear_all),
          onPressed: isActionDisabled ? null : onClearPressed,
          tooltip: 'ล้างข้อมูล',
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}