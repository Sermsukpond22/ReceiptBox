// lib/widgets/action_buttons.dart

import 'package:flutter/material.dart';

class ActionButtons extends StatelessWidget {
  final bool isProcessing;
  final bool isScanning;
  final VoidCallback onSave;
  final VoidCallback onClear;

  const ActionButtons({
    super.key,
    required this.isProcessing,
    required this.isScanning,
    required this.onSave,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = isProcessing || isScanning;

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: isDisabled ? null : onSave,
            icon: isProcessing
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.save),
            label: Text(isProcessing ? 'กำลังบันทึก...' : 'บันทึกใบเสร็จ'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            onPressed: isDisabled ? null : onClear,
            icon: const Icon(Icons.clear_all),
            label: const Text('ล้างข้อมูล'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }
}