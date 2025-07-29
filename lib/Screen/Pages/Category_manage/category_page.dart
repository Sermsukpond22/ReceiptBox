import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cool_alert/cool_alert.dart';
import 'package:run_android/Screen/Pages/Category_manage/Widgets/all_receipt_page.dart';
import 'package:run_android/Screen/Pages/Category_manage/Widgets/category_card.dart';
import 'package:run_android/Screen/Pages/Category_manage/Widgets/receipt_list_page.dart';
import 'package:run_android/Screen/Pages/Category_manage/Widgets/search_bar.dart';
import 'package:run_android/Screen/Pages/Category_manage/Widgets/sort_options.dart';
import 'package:run_android/Screen/Pages/Category_manage/Widgets/statistics_card.dart';
import 'package:run_android/Screen/Pages/Category_manage/Widgets/add_category_dialog.dart';


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
    final newCategoryName = await showDialog<String>(
      context: context,
      builder: (context) => const AddCategoryDialog(),
    );

    if (newCategoryName != null && newCategoryName.isNotEmpty) {
      try {
        await _categoryService.createCategory(newCategoryName);

        // แสดง CoolAlert แจ้งเตือนความสำเร็จ
        if (context.mounted) {
          CoolAlert.show(
            context: context,
            type: CoolAlertType.success,
            text: 'เพิ่มหมวดหมู่ "$newCategoryName" สำเร็จแล้ว!',
            confirmBtnText: 'ตกลง',
            backgroundColor: Colors.green.shade100,
            loopAnimation: false,
          );
        }

        setState(() {}); // รีเฟรช UI
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

  // ฟังก์ชันสำหรับนำทางไปยัง AllUserReceiptsPage
  void _navigateToAllUserReceipts() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AllReceiptsPage(), // ตรวจสอบว่า AllUserReceiptsPage ถูกสร้างไว้ถูกต้อง
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
            Expanded(
              child: StreamBuilder<List<Category>>(
                stream: _categoryService.getAllCategoriesForUser(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                        child: Text(
                      'เกิดข้อผิดพลาด: ${snapshot.error}',
                      style: GoogleFonts.prompt(color: Colors.red),
                    ));
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                        child: Text(
                      'ยังไม่มีหมวดหมู่',
                      style: GoogleFonts.prompt(fontSize: 18, color: Colors.grey),
                    ));
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
                              minimumSize: const Size.fromHeight(50), // ทำให้ปุ่มกว้างเต็ม
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
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddCategoryDialog,
        child: const Icon(Icons.add),
        tooltip: 'เพิ่มหมวดหมู่ใหม่',
      ),
    );
  }
}