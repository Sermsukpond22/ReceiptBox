import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:run_android/Screen/Pages/Category_manage/Widgets/category_card.dart';
import 'package:run_android/Screen/Pages/Category_manage/Widgets/category_list_view.dart';
import 'package:run_android/Screen/Pages/Category_manage/Widgets/search_bar.dart';
import 'package:run_android/Screen/Pages/Category_manage/Widgets/sort_options.dart';
import 'package:run_android/Screen/Pages/Category_manage/Widgets/statistics_card.dart';
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

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filteredList = categories.where((category) {
        return category.name.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Sort categories by name
    filteredList.sort((a, b) {
      int result = a.name.compareTo(b.name);
      return _isAscending ? result : -result;
    });

    return filteredList;
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
                             return CategoryCard(category: filteredCategories[index]);
                          },
                          childCount: filteredCategories.length,
                        ),
                      ),
                       if(filteredCategories.isEmpty)
                       SliverFillRemaining(
                          hasScrollBody: false,
                          child: CategoryListView(
                              categories: filteredCategories,
                              searchQuery: _searchQuery
                          ),
                       )
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
       floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Implement create new category dialog/page
          _categoryService.createCategory("หมวดหมู่ใหม่");
        },
        child: const Icon(Icons.add),
        tooltip: 'เพิ่มหมวดหมู่ใหม่',
      ),
    );
  }
}