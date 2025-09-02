// lib/Screen/Pages/Category_manage/category_page.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cool_alert/cool_alert.dart';
import 'package:run_android/Screen/Pages/Category_manage/Widgets/Category/edit_category_dialog.dart';
import 'package:run_android/Screen/Pages/Category_manage/Widgets/Receipt/all_receipt_page.dart';
import 'package:run_android/Screen/Pages/Category_manage/Widgets/Category/category_card.dart';
import 'package:run_android/Screen/Pages/Category_manage/Widgets/Receipt/receipt_list_page.dart';
import 'package:run_android/Screen/Pages/Category_manage/Widgets/Category/search_bar.dart';
import 'package:run_android/Screen/Pages/Category_manage/Widgets/Category/sort_options.dart';
import 'package:run_android/Screen/Pages/Category_manage/Widgets/Category/statistics_card.dart';
import 'package:run_android/Screen/Pages/Category_manage/Widgets/Category/add_category_dialog.dart';


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

  @override
  void initState() {
    super.initState();
    // สร้างหมวดหมู่พื้นฐาน 5 หมวดหมู่หลักถ้ายังไม่มี
    _categoryService.createDefaultCategoriesIfNotExists();
  }

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
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => const AddCategoryDialog(),
    );

    if (result != null) {
      try {
        await _categoryService.createCategory(
          result['name']!,
          icon: result['icon'],
        );

        // แสดง CoolAlert แจ้งเตือนความสำเร็จ
        if (context.mounted) {
          CoolAlert.show(
            context: context,
            type: CoolAlertType.success,
            text: 'เพิ่มหมวดหมู่ "${result['name']}" สำเร็จแล้ว!',
            confirmBtnText: 'ตกลง',
            backgroundColor: Colors.green.shade100,
            loopAnimation: false,
          );
        }

      } catch (e) {
        if (context.mounted) {
          CoolAlert.show(
            context: context,
            type: CoolAlertType.error,
            title: 'เกิดข้อผิดพลาด',
            text: e.toString(),
            confirmBtnText: 'ปิด',
          );
        }
      }
    }
  }

  // ฟังก์ชันแสดง Dialog จัดการหมวดหมู่ (แก้ไข/ลบ)
  Future<void> _showEditCategoryDialog(Category category) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => EditCategoryDialog(category: category),
    );

    // ไม่จำเป็นต้องทำ setState() เพราะ StreamBuilder จะรีเฟรชอัตโนมัติ
    // หาก result เป็น true แสดงว่ามีการอัปเดตหรือลบสำเร็จ
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                // รีเฟรชข้อมูล
              });
            },
            tooltip: 'รีเฟรชข้อมูล',
          ),
        ],
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
            Expanded(
              child: StreamBuilder<List<Category>>(
                stream: _categoryService.getAllCategoriesForUser(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('กำลังโหลดข้อมูล...'),
                        ],
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Colors.red.shade300,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'เกิดข้อผิดพลาด',
                            style: GoogleFonts.prompt(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${snapshot.error}',
                            style: GoogleFonts.prompt(color: Colors.red),
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
                          Icon(
                            Icons.category_outlined,
                            size: 64,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'ยังไม่มีหมวดหมู่',
                            style: GoogleFonts.prompt(
                              fontSize: 18,
                              color: Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'เริ่มต้นโดยการเพิ่มหมวดหมู่ใหม่',
                            style: GoogleFonts.prompt(
                              fontSize: 14,
                              color: Colors.grey.shade600,
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
                      
                      // ปุ่ม "ดูใบเสร็จทั้งหมด"
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
                              elevation: 2,
                            ),
                          ),
                        ),
                      ),
                      
                      // หัวข้อรายการหมวดหมู่
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 10.0),
                          child: Row(
                            children: [
                              Text(
                                "รายการหมวดหมู่",
                                style: GoogleFonts.prompt(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '${filteredCategories.length} รายการ',
                                style: GoogleFonts.prompt(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      // รายการหมวดหมู่
                      if (filteredCategories.isEmpty)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.search_off,
                                  size: 48,
                                  color: Colors.grey.shade300,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'ไม่พบหมวดหมู่ที่ค้นหา',
                                  style: GoogleFonts.prompt(
                                    fontSize: 16,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                Text(
                                  'ลองค้นหาด้วยคำอื่น',
                                  style: GoogleFonts.prompt(
                                    fontSize: 14,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        SliverList(
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
                                onLongPress: () {
                                  // เมื่อกดค้างให้แสดง Dialog แก้ไข/ลบ
                                  _showEditCategoryDialog(category);
                                },
                              );
                            },
                            childCount: filteredCategories.length,
                          ),
                        ),
                      
                      // เพิ่มพื้นที่ว่างด้านล่างเพื่อไม่ให้ FloatingActionButton บัง
                      const SliverToBoxAdapter(
                        child: SizedBox(height: 80),
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
        onPressed: _showAddCategoryDialog,
        icon: const Icon(Icons.add),
        label: Text(
          'เพิ่มหมวดหมู่',
          style: GoogleFonts.prompt(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
    );
  }
}