import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:run_android/Screen/Pages/Category_manage/Widgets/receipt_SearchBar.dart';
import 'receipt_detail_page.dart';

// ✨ 1. สร้าง enum เพื่อจัดการตัวเลือกการจัดเรียงให้ชัดเจน
enum SortOption {
  byDate,
  byPrice,
  byName,
}

// Helper function สำหรับแสดงชื่อตัวเลือกการจัดเรียง
extension SortOptionExtension on SortOption {
  String get displayName {
    switch (this) {
      case SortOption.byDate:
        return 'เรียงตามวันที่';
      case SortOption.byPrice:
        return 'เรียงตามราคา';
      case SortOption.byName:
        return 'เรียงตามชื่อร้าน';
      default:
        return '';
    }
  }
}

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
  final _searchController = TextEditingController();
  String _searchQuery = '';
  Timer? _debounce;

  // ✨ 2. เพิ่ม State สำหรับเก็บตัวเลือกการจัดเรียงปัจจุบัน (ค่าเริ่มต้นคือวันที่)
  SortOption _currentSortOption = SortOption.byDate;

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

  Stream<QuerySnapshot<Map<String, dynamic>>> _buildStream() {
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection('receipts')
        .where('categoryId', isEqualTo: widget.categoryId);

    if (_searchQuery.isNotEmpty) {
      // เมื่อมีการค้นหา จะเรียงตามชื่อร้านเสมอ
      query = query
          .where('storeName', isGreaterThanOrEqualTo: _searchQuery)
          .where('storeName', isLessThanOrEqualTo: '$_searchQuery\uf8ff')
          .orderBy('storeName');
    } else {
      // ✨ 4. ปรับ Logic การเรียงข้อมูลตาม _currentSortOption เมื่อไม่มีการค้นหา
      switch (_currentSortOption) {
        case SortOption.byPrice:
          query = query.orderBy('amount', descending: true); // ราคาสูง -> ต่ำ
          break;
        case SortOption.byName:
          query = query.orderBy('storeName', descending: false); // ก -> ฮ
          break;
        case SortOption.byDate:
        default: // ค่าเริ่มต้น
          // เรียงตามวันที่ทำรายการ (ใหม่ -> เก่า)
          query = query.orderBy('transactionDate', descending: true);
          break;
      }
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
        // ✨ 3. เพิ่มปุ่ม Filter สำหรับการจัดเรียง
        actions: [
          PopupMenuButton<SortOption>(
            icon: const Icon(Icons.filter_list),
            onSelected: (SortOption result) {
              setState(() {
                _currentSortOption = result; // อัปเดต State เมื่อผู้ใช้เลือก
              });
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<SortOption>>[
              for (var option in SortOption.values)
                PopupMenuItem<SortOption>(
                  value: option,
                  child: Text(
                    option.displayName,
                    style: GoogleFonts.prompt(),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          CategorySearchBar(
            controller: _searchController,
            onChanged: (value) {},
            onClear: _clearSearch,
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _buildStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator(color: primaryColor));
                }

                if (snapshot.hasError) {
                  // แสดงข้อความแนะนำให้สร้าง Index
                  return _buildErrorState(snapshot.error.toString());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
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
  // Widget สำหรับแสดงข้อผิดพลาด (โดยเฉพาะเรื่อง Index)
  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 60),
            const SizedBox(height: 16),
            Text('เกิดข้อผิดพลาด', style: GoogleFonts.prompt(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              'อาจเกิดจากคุณยังไม่ได้สร้าง Index ใน Firestore สำหรับการ Query นี้\nโปรดตรวจสอบ Log ใน Console เพื่อดู Link สำหรับสร้าง Index ที่ต้องการ',
              textAlign: TextAlign.center,
              style: GoogleFonts.prompt(fontSize: 14, color: Colors.grey[700]),
            ),
             const SizedBox(height: 16),
            Text(
              'Error: $error', // แสดง error จริงๆ ด้วยเผื่อเป็นปัญหาอื่น
              textAlign: TextAlign.center,
              style: GoogleFonts.prompt(fontSize: 12, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }
}
