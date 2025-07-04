import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SortOptions extends StatelessWidget {
  final bool isAscending;
  final ValueChanged<bool> onOrderChanged;

  const SortOptions({
    Key? key,
    required this.isAscending,
    required this.onOrderChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            'เรียงตามชื่อ: ',
            style: GoogleFonts.prompt(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: Row(
              children: [
                Icon(
                  isAscending ? Icons.arrow_upward : Icons.arrow_downward,
                  size: 16,
                  color: Colors.grey[800],
                ),
                const SizedBox(width: 6),
                Text(
                  isAscending ? 'ก-ฮ' : 'ฮ-ก',
                  style: GoogleFonts.prompt(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.grey[200],
            onSelected: (selected) {
              onOrderChanged(!isAscending);
            },
          ),
        ],
      ),
    );
  }
}