import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // 
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:run_android/Screen/Pages/Category_manage/Widgets/Receipt/receipt_SearchBar.dart';
import 'package:run_android/Screen/Pages/Category_manage/Widgets/Receipt/receipt_detail_page.dart';



// ✨ คัดลอก enum และ extension มาจากหน้า ReceiptList เพื่อใช้ร่วมกัน
enum SortOption { byDate, byPrice, byName }

extension SortOptionExtension on SortOption {
  String get displayName {
    switch (this) {
      case SortOption.byDate: return 'เรียงตามวันที่';
      case SortOption.byPrice: return 'เรียงตามราคา';
      case SortOption.byName: return 'เรียงตามชื่อร้าน';
    }
  }
}

class AllReceiptsPage extends StatefulWidget {
  const AllReceiptsPage({Key? key}) : super(key: key);

  @override
  State<AllReceiptsPage> createState() => _AllReceiptsPageState();
}

class _AllReceiptsPageState extends State<AllReceiptsPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  Timer? _debounce;
  SortOption _currentSortOption = SortOption.byDate;
  final User? _currentUser = FirebaseAuth.instance.currentUser; // 👈 ดึงข้อมูลผู้ใช้ปัจจุบัน

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
    // 👈 ตรวจสอบว่ามีผู้ใช้ล็อกอินอยู่หรือไม่
    if (_currentUser == null) {
      return Stream.value(const QuerySnapshotEmpty()); // คืนค่า Stream ว่าง
    }

    // ✅ เปลี่ยน Query หลัก: จาก 'categoryId' เป็น 'userId'
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection('receipts')
        .where('userId', isEqualTo: _currentUser!.uid); // ใช้ uid ของผู้ใช้ปัจจุบัน

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
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        title: Text(
          'ใบเสร็จทั้งหมด', // ✅ เปลี่ยน Title
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
            child: _currentUser == null
                ? _buildLoginRequiredState() // 👈 แสดงผลถ้าผู้ใช้ยังไม่ล็อกอิน
                : StreamBuilder<QuerySnapshot>(
                    stream: _buildStream(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator(color: primaryColor));
                      }
                      if (snapshot.hasError) {
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

  // --- Helper Widgets (คัดลอกมาจาก ReceiptList) ---

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
              'ยังไม่มีใบเสร็จในบัญชีของคุณ',
              style: GoogleFonts.prompt(fontSize: 18, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }
  }
  
  Widget _buildLoginRequiredState() {
     return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.login, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'กรุณาเข้าสู่ระบบ',
              style: GoogleFonts.prompt(fontSize: 18, color: Colors.grey[600]),
            ),
             const SizedBox(height: 8),
            Text(
              'เพื่อดูรายการใบเสร็จของคุณ',
              style: GoogleFonts.prompt(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Text('เกิดข้อผิดพลาด: $error', style: GoogleFonts.prompt()),
      ),
    );
  }

  Widget _buildReceiptCard(BuildContext context, Map<String, dynamic> data, Color primaryColor) {
    final storeName = data['storeName'] ?? 'ไม่ระบุร้านค้า';
    final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
    final imageUrl = data['imageUrl'] as String?;
    final docId = data['docId'] as String;

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
                      errorBuilder: (context, error, stackTrace) => Container(width: 60, height: 60, color: Colors.grey[200], child: Icon(Icons.hide_image_outlined, color: Colors.grey[400])),
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
                child: Text(storeName, style: GoogleFonts.prompt(fontWeight: FontWeight.w600, fontSize: 17), maxLines: 1, overflow: TextOverflow.ellipsis),
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

// Helper class for empty stream
class QuerySnapshotEmpty implements QuerySnapshot<Map<String, dynamic>> {
  const QuerySnapshotEmpty();
  @override
  List<QueryDocumentSnapshot<Map<String, dynamic>>> get docs => [];
  @override
  List<DocumentChange<Map<String, dynamic>>> get docChanges => [];
  @override
  SnapshotMetadata get metadata => throw UnimplementedError();
  @override
  int get size => 0;
}
