import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'receipt_detail_page.dart';

class ReceiptList extends StatelessWidget {
  final String categoryId;
  final String categoryName;

  const ReceiptList({
    Key? key,
    required this.categoryId,
    required this.categoryName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final receiptsRef = FirebaseFirestore.instance
        .collection('receipts')
        .where('categoryId', isEqualTo: categoryId)
        .orderBy('createdAt', descending: true);

    // กำหนด Theme สีหลักเพื่อง่ายต่อการปรับแก้
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;

    return Scaffold(
      // เปลี่ยนสีพื้นหลังให้ Card ดูเด่นขึ้น
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        // ทำให้ AppBar ดูสะอาดตา
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        title: Text(
          'ใบเสร็จ: $categoryName',
          style: GoogleFonts.prompt(fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: receiptsRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: primaryColor));
          }

          if (snapshot.hasError) {
            return Center(
                child: Text('เกิดข้อผิดพลาด: ${snapshot.error}',
                    style: GoogleFonts.prompt()));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            // ปรับปรุงหน้าจอเมื่อไม่มีข้อมูล
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inbox_outlined,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'ยังไม่มีใบเสร็จในหมวดหมู่นี้',
                    style:
                        GoogleFonts.prompt(fontSize: 18, color: Colors.grey[600]),
                  ),
                  Text(
                    'ลองเพิ่มใบเสร็จใหม่สิ!',
                    style: GoogleFonts.prompt(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final docs = snapshot.data!.docs;

          // ใช้ ListView.separated เพื่อเพิ่มเส้นคั่นระหว่างรายการ
          return ListView.separated(
            padding: const EdgeInsets.all(16.0), // เพิ่มระยะห่างรอบๆ List
            itemCount: docs.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final doc = docs[index];
              // ปรับปรุงการเข้าถึงข้อมูลให้ปลอดภัยมากขึ้น
              final data = doc.data() as Map<String, dynamic>? ?? {};

              final storeName = data['storeName'] ?? 'ไม่ระบุร้านค้า';
              final description = data['description'] ?? 'ไม่มีรายละเอียด';
              final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
              final transactionDate = (data['transactionDate'] as Timestamp?)?.toDate();
              final imageUrl = data['imageUrl'] as String?; // ดึง imageUrl มาด้วย

              final formattedDate = transactionDate != null
                  ? DateFormat('dd MMM yy', 'th').format(transactionDate)
                  : 'N/A';

              // เพิ่ม doc.id เข้าไปใน Map เพื่อส่งไปยัง ReceiptDetailPage
              // **สำคัญมาก** เพื่อใช้เป็น Hero Tag ที่ไม่ซ้ำกัน
              data['docId'] = doc.id;

              // ใช้ Card ที่ออกแบบใหม่
              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                clipBehavior: Clip.antiAlias, // ทำให้ InkWell อยู่ในขอบมน
                child: InkWell(
                  // เพิ่ม InkWell เพื่อให้มี animation ตอนกด
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ReceiptDetailPage(receiptData: data),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        // เพิ่ม Hero Widget ที่นี่สำหรับรูปภาพ (ถ้ามี)
                        // Tag ต้องไม่ซ้ำกันสำหรับแต่ละรายการ
                        // และต้องตรงกับ Tag ใน ReceiptDetailPage
                        if (imageUrl != null && imageUrl.isNotEmpty)
                          Hero(
                            tag: 'receipt-image-${doc.id}', // ใช้ doc.id เพื่อให้ tag ไม่ซ้ำกัน
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8.0), // ทำให้รูปภาพมีขอบมน
                              child: Image.network(
                                imageUrl,
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Container(
                                    width: 60,
                                    height: 60,
                                    color: Colors.grey[200],
                                    child: Center(child: CircularProgressIndicator(value: loadingProgress.expectedTotalBytes != null ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes! : null)),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) => Container(
                                  width: 60,
                                  height: 60,
                                  color: Colors.grey[200],
                                  child: Icon(Icons.image_outlined, color: Colors.grey[400]),
                                ),
                              ),
                            ),
                          )
                        else
                          // Icon Placeholder หากไม่มีรูปภาพ
                          CircleAvatar(
                            backgroundColor: primaryColor.withOpacity(0.1),
                            foregroundColor: primaryColor,
                            child: const Icon(Icons.receipt_long),
                          ),
                        const SizedBox(width: 16),
                        // จัดวางข้อความใหม่
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                storeName,
                                style: GoogleFonts.prompt(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 17,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                description,
                                style: GoogleFonts.prompt(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(Icons.calendar_today_outlined, size: 12, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text(
                                    formattedDate,
                                    style: GoogleFonts.prompt(color: Colors.grey, fontSize: 12),
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        // จัดวางราคา
                        Text(
                          '${NumberFormat("#,##0.00").format(amount)} ฿',
                          style: GoogleFonts.prompt(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[800],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      // เพิ่มปุ่มสำหรับสร้างใบเสร็จใหม่
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: เพิ่มโค้ดสำหรับไปยังหน้าเพิ่มใบเสร็จ
          print('Add new receipt');
        },
        backgroundColor: primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}