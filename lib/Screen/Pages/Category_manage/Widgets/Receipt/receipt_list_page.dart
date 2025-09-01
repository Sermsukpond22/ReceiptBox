import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:run_android/Screen/Pages/Category_manage/Widgets/Receipt/receipt_SearchBar.dart';
import 'package:run_android/Screen/Pages/Category_manage/Widgets/Receipt/receipt_grouped_list.dart';



// ✨ สร้าง enum เพื่อจัดการตัวเลือกการจัดเรียงให้ชัดเจน
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
    // setState จะถูกเรียกโดย listener อยู่แล้ว
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _buildStream() {
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection('receipts')
        .where('categoryId', isEqualTo: widget.categoryId);

    // ปรับการเรียงข้อมูลตามเงื่อนไข
    if (_searchQuery.isNotEmpty) {
      query = query
          .where('storeName', isGreaterThanOrEqualTo: _searchQuery)
          .where('storeName', isLessThanOrEqualTo: '$_searchQuery\uf8ff')
          .orderBy('storeName');
    } else {
      switch (_currentSortOption) {
        case SortOption.byPrice:
          query = query.orderBy('amount', descending: true);
          break;
        case SortOption.byName:
          query = query.orderBy('storeName', descending: false);
          break;
        case SortOption.byDate:
        default:
          query = query.orderBy('transactionDate', descending: true);
          break;
      }
    }
    return query.snapshots();
  }

  @override
  Widget build(BuildContext context) {
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
        actions: [
          PopupMenuButton<SortOption>(
            icon: const Icon(Icons.filter_list),
            onSelected: (SortOption result) {
              setState(() {
                _currentSortOption = result;
              });
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<SortOption>>[
              for (var option in SortOption.values)
                PopupMenuItem<SortOption>(
                  value: option,
                  child: Text(option.displayName, style: GoogleFonts.prompt()),
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
                  return Center(child: CircularProgressIndicator(color: Theme.of(context).primaryColor));
                }
                if (snapshot.hasError) {
                  return _buildErrorState(snapshot.error.toString());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyState();
                }

                // ✨ ส่งข้อมูลไปให้ Widget ใหม่จัดการแสดงผล
                return ReceiptGroupedListView(docs: snapshot.data!.docs);
              },
            ),
          ),
        ],
      ),
    );
  }

  // Helper Widgets ยังคงอยู่ที่นี่เพื่อจัดการ State หลักของหน้า
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty
                ? 'ไม่พบผลลัพธ์สำหรับ "$_searchQuery"'
                : 'ยังไม่มีใบเสร็จในหมวดหมู่นี้',
            style: GoogleFonts.prompt(fontSize: 18, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
  
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
              'Error: $error',
              textAlign: TextAlign.center,
              style: GoogleFonts.prompt(fontSize: 12, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }
}