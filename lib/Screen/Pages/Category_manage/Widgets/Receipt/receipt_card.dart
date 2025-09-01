import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:run_android/Screen/Pages/Category_manage/Widgets/Receipt/receipt_detail_page.dart';

class ReceiptCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const ReceiptCard({Key? key, required this.data}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final storeName = data['storeName'] ?? 'ไม่ระบุร้านค้า';
    final description = data['description'] ?? 'ไม่มีรายละเอียด';
    final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
    // --- เปลี่ยนการดึงข้อมูลจาก transactionDate เป็น createdAt ---
    final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
    final imageUrl = data['imageUrl'] as String?;
    final docId = data['docId'] as String;

    // --- แก้ไขรูปแบบการแสดงผลวันที่ให้เป็นเดือนแบบย่อ ---
    final String formattedCreatedAt = createdAt != null
        ? DateFormat('d MMM yyyy, HH:mm', 'th').format(createdAt)
        : 'ไม่ระบุวันเวลา';

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ReceiptDetailPage(receiptData: data)),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // --- ส่วนรูปภาพ (เหมือนเดิม) ---
              SizedBox(
                width: 60,
                child: Hero(
                  tag: 'receipt-image-$docId',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12.0),
                    child: imageUrl != null && imageUrl.isNotEmpty
                        ? Image.network(
                            imageUrl,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => _buildPlaceholderIcon(context),
                          )
                        : _buildPlaceholderIcon(context),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // ✨✨ --- ปรับโครงสร้างส่วนข้อมูลทั้งหมดให้อยู่ใน Expanded เดียว --- ✨✨
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ชื่อร้าน (เหมือนเดิม)
                    Text(
                      storeName,
                      style: GoogleFonts.prompt(fontWeight: FontWeight.w600, fontSize: 17),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // รายละเอียด (เหมือนเดิม)
                    Text(
                      description,
                      style: GoogleFonts.prompt(color: Colors.grey[600], fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),

                    // ✨ สร้าง Row ใหม่เพื่อจัดวาง วันที่และยอดเงิน ให้อยู่บรรทัดเดียวกัน
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween, // จัดให้อยู่คนละฝั่ง
                      crossAxisAlignment: CrossAxisAlignment.end, // จัดให้ชิดด้านล่าง
                      children: [
                        // --- ส่วนของวันที่ (ทำให้ยืดหยุ่น) ---
                        Expanded(
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey[500]),
                              const SizedBox(width: 4),
                              // ทำให้ข้อความวันที่ยืดหยุ่นและตัดคำได้หากยาวเกิน
                              Flexible(
                                child: Text(
                                  // --- ใช้ formattedCreatedAt ที่ปรับปรุงแล้ว ---
                                  formattedCreatedAt,
                                  style: GoogleFonts.prompt(color: Colors.grey[600], fontSize: 13),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // --- ส่วนของยอดเงิน ---
                        const SizedBox(width: 8), // เพิ่มระยะห่างเล็กน้อย
                        Text(
                          '${NumberFormat("#,##0.00").format(amount)} ฿',
                          style: GoogleFonts.prompt(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[800]),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Add this method to provide a placeholder icon when the image is not available
  Widget _buildPlaceholderIcon(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Icon(
        Icons.receipt_long,
        color: Colors.grey[400],
        size: 32,
      ),
    );
  }
}