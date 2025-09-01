import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cool_alert/cool_alert.dart';
import 'package:run_android/Screen/Pages/Category_manage/Widgets/Receipt/all_receipt_page.dart';
import 'package:run_android/Screen/Pages/Category_manage/Widgets/Categoty/category_card.dart';
import 'package:run_android/Screen/Pages/Category_manage/Widgets/Receipt/receipt_list_page.dart';
import 'package:run_android/Screen/Pages/Category_manage/Widgets/Categoty/search_bar.dart';
import 'package:run_android/Screen/Pages/Category_manage/Widgets/Categoty/sort_options.dart';
import 'package:run_android/Screen/Pages/Category_manage/Widgets/Categoty/statistics_card.dart';
import 'package:run_android/Screen/Pages/Category_manage/Widgets/Categoty/add_category_dialog.dart';

import 'package:run_android/models/category_model.dart';
import 'package:run_android/services/categories_service.dart';

class CategoryPage extends StatefulWidget {
  const CategoryPage({Key? key}) : super(key: key);

  @override
  _CategoryPageState createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  final CategoryService _categoryService = CategoryService();
  String _searchQuery = '';
  bool _isAscending = true;
  bool _isLoading = false;

  List<Category> _filterAndSortCategories(List<Category> categories) {
    List<Category> filteredList = categories;

    if (_searchQuery.isNotEmpty) {
      filteredList = categories.where((category) {
        return category.name.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    filteredList.sort((a, b) {
      int result = a.name.compareTo(b.name);
      return _isAscending ? result : -result;
    });

    return filteredList;
  }

  Future<void> _showAddCategoryDialog() async {
    final newCategoryData = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false, // ป้องกันการปิด dialog โดยการแตะนอก dialog
      builder: (context) => const AddCategoryDialog(),
    );

    if (newCategoryData != null) {
      setState(() {
        _isLoading = true;
      });

      try {
        // เรียกใช้ service เพื่อสร้างหมวดหมู่ใหม่
        await _categoryService.createCategory(
          newCategoryData['name'] as String,
          icon: newCategoryData['icon'] as String,
        );

        // แสดงการแจ้งเตือนความสำเร็จ
        if (context.mounted) {
          await CoolAlert.show(
            context: context,
            type: CoolAlertType.success,
            title: 'สำเร็จ!',
            text: 'เพิ่มหมวดหมู่ "${newCategoryData['name']}" สำเร็จแล้ว!',
            confirmBtnText: 'ตกลง',
            backgroundColor: Colors.green.shade100,
            confirmBtnColor: Colors.green,
            loopAnimation: false,
            animType: CoolAlertAnimType.slideInUp,
          );
        }

        // UI จะอัพเดทอัตโนมัติเนื่องจากใช้ StreamBuilder
      } catch (e) {
        if (context.mounted) {
          await CoolAlert.show(
            context: context,
            type: CoolAlertType.error,
            title: 'เกิดข้อผิดพลาด',
            text: 'ไม่สามารถเพิ่มหมวดหมู่ได้: ${e.toString()}',
            confirmBtnText: 'ปิด',
            confirmBtnColor: Colors.red,
            animType: CoolAlertAnimType.slideInDown,
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  // ฟังก์ชันสำหรับนำทางไปยัง AllUserReceiptsPage
  void _navigateToAllUserReceipts() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AllReceiptsPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'จัดการหมวดหมู่',
          style: GoogleFonts.prompt(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        foregroundColor: Colors.black87,
      ),
      body: SafeArea(
        child: Column(
          children: [
            CategorySearchBar(
              searchQuery: _searchQuery,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              onClear: () {
                setState(() {
                  _searchQuery = '';
                });
              },
            ),
            SortOptions(
              isAscending: _isAscending,
              onOrderChanged: (isAsc) {
                setState(() {
                  _isAscending = isAsc;
                });
              },
            ),
            
            // แสดง Loading indicator หากกำลังเพิ่มหมวดหมู่
            if (_isLoading) ...[
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'กำลังเพิ่มหมวดหมู่...',
                      style: GoogleFonts.prompt(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            Expanded(
              child: StreamBuilder<List<Category>>(
                stream: _categoryService.getAllCategoriesForUser(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 60,
                            color: Colors.red[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'เกิดข้อผิดพลาด',
                            style: GoogleFonts.prompt(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.red[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${snapshot.error}',
                            style: GoogleFonts.prompt(
                              color: Colors.red[500],
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.category,
                              size: 80,
                              color: Colors.grey[400],
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'ยังไม่มีหมวดหมู่',
                            style: GoogleFonts.prompt(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'เพิ่มหมวดหมู่แรกของคุณ',
                            style: GoogleFonts.prompt(
                              fontSize: 16,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final allCategories = snapshot.data!;
                  final filteredCategories = _filterAndSortCategories(allCategories);

                  return CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: StatisticsCard(categories: allCategories),
                      ),
                      // เพิ่มปุ่ม "ดูใบเสร็จทั้งหมด" ตรงนี้
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 10.0),
                          child: ElevatedButton.icon(
                            onPressed: _navigateToAllUserReceipts,
                            icon: const Icon(Icons.receipt_long),
                            label: Text(
                              'ดูใบเสร็จทั้งหมด',
                              style: GoogleFonts.prompt(fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size.fromHeight(50),
                              backgroundColor: Colors.blue.shade600,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 10.0),
                          child: Text(
                            "รายการหมวดหมู่",
                            style: GoogleFonts.prompt(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ),
                      
                      // แสดงรายการหมวดหมู่หรือสถานะว่าง
                      filteredCategories.isEmpty && _searchQuery.isNotEmpty
                          ? SliverFillRemaining(
                              child: _buildEmptySearchState(),
                            )
                          : SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final category = filteredCategories[index];
                                  return CategoryCard(
                                    category: category,
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ReceiptList(
                                            categoryId: category.id,
                                            categoryName: category.name,
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                                childCount: filteredCategories.length,
                              ),
                            ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isLoading ? null : _showAddCategoryDialog,
        icon: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.add),
        label: Text(
          _isLoading ? 'กำลังเพิ่ม...' : 'เพิ่มหมวดหมู่',
          style: GoogleFonts.prompt(fontWeight: FontWeight.bold),
        ),
        backgroundColor: _isLoading 
            ? Colors.grey[400] 
            : Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildEmptySearchState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.search_off, size: 60, color: Colors.grey[400]),
          ),
          const SizedBox(height: 24),
          Text(
            'ไม่พบหมวดหมู่ที่ค้นหา',
            style: GoogleFonts.prompt(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'ลองใช้คำค้นหาอื่น หรือเพิ่มหมวดหมู่ใหม่',
            style: GoogleFonts.prompt(
              fontSize: 16,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}