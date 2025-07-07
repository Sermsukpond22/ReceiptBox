import 'dart:async'; // ✨ 1. Import สำหรับ Debounce
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:run_android/Screen/Pages/Category_manage/Widgets/receipt_SearchBar.dart';
import 'receipt_detail_page.dart';


// ✨ 3. แปลงเป็น StatefulWidget
class ReceiptList extends StatefulWidget {
  final String categoryId;
  final String categoryName;

  const ReceiptList({
    Key? key,
    required this.categoryId,
    required this.categoryName,
  }) : super(key: key);

  @override
  State<ReceiptList> createState() => _ReceiptListState();
}

class _ReceiptListState extends State<ReceiptList> {
  // ✨ 4. สร้าง State สำหรับจัดการการค้นหา
  final _searchController = TextEditingController();
  String _searchQuery = '';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // ฟังก์ชัน Debounce ป้องกันการ query ขณะพิมพ์
  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted) {
        setState(() {
          _searchQuery = _searchController.text.trim();
        });
      }
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
    });
  }

  // ✨ 5. สร้าง Stream แบบไดนามิกตาม _searchQuery
  Stream<QuerySnapshot<Map<String, dynamic>>> _buildStream() {
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection('receipts')
        .where('categoryId', isEqualTo: widget.categoryId);

    if (_searchQuery.isNotEmpty) {
      // ค้นหาจาก storeName ที่ขึ้นต้นด้วยคำค้นหา
      query = query
          .where('storeName', isGreaterThanOrEqualTo: _searchQuery)
          .where('storeName', isLessThanOrEqualTo: '$_searchQuery\uf8ff')
          .orderBy('storeName'); // **สำคัญ:** ต้อง orderBy field ที่ใช้ inequality
    } else {
      // ถ้าไม่มีคำค้นหา ให้เรียงตามวันที่สร้างเหมือนเดิม
      query = query.orderBy('createdAt', descending: true);
    }

    return query.snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        title: Text(
          'ใบเสร็จ: ${widget.categoryName}',
          style: GoogleFonts.prompt(fontWeight: FontWeight.bold),
        ),
        // ไม่ต้องมีปุ่มค้นหาที่ AppBar แล้ว
      ),
      // ✨ 6. ใช้ Column เพื่อวาง SearchBar และ ListView
      body: Column(
        children: [
          CategorySearchBar(
            controller: _searchController,
            onChanged: (value) {
              // onChanged ของ TextField จะ trigger listener ที่เราตั้งไว้ใน initState
            },
            onClear: _clearSearch,
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _buildStream(), // ใช้ stream จากฟังก์ชันที่สร้างไว้
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator(color: primaryColor));
                }

                if (snapshot.hasError) {
                  return Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}', style: GoogleFonts.prompt()));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  // แสดงผลตามสถานการณ์ (มีคำค้นหาหรือไม่)
                  return _buildEmptyState();
                }

                final docs = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>? ?? {};
                    data['docId'] = doc.id;
                    // ใช้ Widget เดิมในการแสดงผล Card
                    return _buildReceiptCard(context, data, primaryColor);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Widget สำหรับแสดงผลเมื่อไม่มีข้อมูล
  Widget _buildEmptyState() {
    if (_searchQuery.isNotEmpty) {
      return Center(
        child: Text(
          'ไม่พบผลลัพธ์สำหรับ "$_searchQuery"',
          style: GoogleFonts.prompt(fontSize: 16, color: Colors.grey[600]),
        ),
      );
    } else {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'ยังไม่มีใบเสร็จในหมวดหมู่นี้',
              style: GoogleFonts.prompt(fontSize: 18, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }
  }

  // แยก Widget Card ออกมาเพื่อความสะอาด
  Widget _buildReceiptCard(BuildContext context, Map<String, dynamic> data, Color primaryColor) {
    final storeName = data['storeName'] ?? 'ไม่ระบุร้านค้า';
    final description = data['description'] ?? 'ไม่มีรายละเอียด';
    final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
    final transactionDate = (data['transactionDate'] as Timestamp?)?.toDate();
    final imageUrl = data['imageUrl'] as String?;
    final docId = data['docId'] as String;

    final formattedDate = transactionDate != null
        ? DateFormat('dd MMM yy', 'th').format(transactionDate)
        : 'N/A';

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
              if (imageUrl != null && imageUrl.isNotEmpty)
                Hero(
                  tag: 'receipt-image-$docId',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: Image.network(
                      imageUrl,
                      width: 60, height: 60, fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(width: 60, height: 60, color: Colors.grey[200], child: Icon(Icons.image_outlined, color: Colors.grey[400])),
                    ),
                  ),
                )
              else
                CircleAvatar(
                  radius: 30,
                  backgroundColor: primaryColor.withOpacity(0.1),
                  foregroundColor: primaryColor,
                  child: const Icon(Icons.receipt_long),
                ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(storeName, style: GoogleFonts.prompt(fontWeight: FontWeight.w600, fontSize: 17), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(description, style: GoogleFonts.prompt(color: Colors.grey[600], fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Text(
                '${NumberFormat("#,##0.00").format(amount)} ฿',
                style: GoogleFonts.prompt(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green[800]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}