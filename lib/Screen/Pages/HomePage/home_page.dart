import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:run_android/Screen/Pages/HomePage/widgets/balance_card_widget.dart';
import 'package:run_android/Screen/Pages/HomePage/widgets/categories_grid_widget.dart';
import 'package:run_android/Screen/Pages/HomePage/widgets/expense_bar_chart.dart';
import 'package:run_android/Screen/Pages/HomePage/widgets/header_widget.dart';
import 'package:run_android/Screen/Pages/HomePage/widgets/recent_transactions_list.dart';

// ✅ 1. Import Service และ Model ที่จำเป็น
import 'package:run_android/services/categories_service.dart';
import 'package:run_android/models/category_model.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final User? user = FirebaseAuth.instance.currentUser;
  
  // ✅ 2. สร้าง instance ของ Service
  final CategoryService _categoryService = CategoryService();

  // ✅ 3. เปลี่ยน State ทั้งหมดให้เป็น Stream
  late Stream<QuerySnapshot> _transactionsStream;
  late Stream<DocumentSnapshot> _userProfileStream;
  late Stream<List<Category>> _categoriesStream;

  @override
  void initState() {
    super.initState();
    if (user != null) {
      final firestore = FirebaseFirestore.instance;
      _transactionsStream = firestore
          .collection('receipts')
          .where('userId', isEqualTo: user!.uid)
          .orderBy('transactionDate', descending: true)
          .snapshots();

      _userProfileStream =
          firestore.collection('users').doc(user!.uid).snapshots();
      
      // ✅ 4. เรียกใช้ Stream จาก Service โดยตรง
      _categoriesStream = _categoryService.getAllCategoriesForUser();
    }
  }

  // ❌ 5. ลบฟังก์ชัน _fetchCategories() ทั้งหมดออกไป

  /// ✅ 6. ปรับปรุงฟังก์ชันให้รับ List<Category>
  List<CategoryExpense> _getCategoryExpenses(List<QueryDocumentSnapshot> transactions, List<Category> categories) {
    Map<String, double> categoryExpenseMap = {};
    Map<String, Color> categoryColorMap = {};
    final List<Color> predefinedColors = [
      Colors.blue, Colors.red, Colors.green, Colors.orange, Colors.purple,
      Colors.teal, Colors.brown, Colors.pink, Colors.indigo, Colors.amber,
    ];
    int colorIndex = 0;

    // ✅ ใช้ข้อมูลจาก List<Category> ที่รับเข้ามา
    for (var cat in categories) {
      categoryExpenseMap[cat.name] = 0.0;
      categoryColorMap[cat.name] = predefinedColors[colorIndex % predefinedColors.length];
      colorIndex++;
    }

    for (var doc in transactions) {
      final data = doc.data() as Map<String, dynamic>;
      final amount = (data['amount'] as num).toDouble();
      final categoryName = data['categoryName'] as String? ?? 'ไม่ระบุหมวดหมู่'; // แนะนำให้ใช้ categoryName ที่ตรงกัน

      if (amount < 0) {
        categoryExpenseMap.update(
          categoryName,
          (value) => value + amount.abs(),
          ifAbsent: () => amount.abs(),
        );
        if (!categoryColorMap.containsKey(categoryName)) {
            categoryColorMap[categoryName] = predefinedColors[colorIndex % predefinedColors.length];
            colorIndex++;
        }
      }
    }

    List<CategoryExpense> categoryExpenses = [];
    categoryExpenseMap.forEach((name, amount) {
      if (amount > 0) {
        categoryExpenses.add(CategoryExpense(name, amount, categoryColorMap[name]!));
      }
    });

    categoryExpenses.sort((a, b) => b.amount.compareTo(a.amount));
    return categoryExpenses;
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Scaffold(body: Center(child: Text("กรุณาเข้าสู่ระบบ")));
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      // ✅ 7. สร้าง StreamBuilder ซ้อนกันเพื่อรวมข้อมูลจาก 2 Streams
      body: StreamBuilder<List<Category>>(
        stream: _categoriesStream,
        builder: (context, categorySnapshot) {
          return StreamBuilder<QuerySnapshot>(
            stream: _transactionsStream,
            builder: (context, transactionSnapshot) {
              
              // --- จัดการสถานะ Loading และ Error ของทั้ง 2 Streams ---
              if (categorySnapshot.connectionState == ConnectionState.waiting ||
                  transactionSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (categorySnapshot.hasError) {
                return Center(child: Text('เกิดข้อผิดพลาดในการโหลดหมวดหมู่: ${categorySnapshot.error}'));
              }
              if (transactionSnapshot.hasError) {
                return Center(child: Text('เกิดข้อผิดพลาดในการโหลดรายการ: ${transactionSnapshot.error}'));
              }
              
              // --- เมื่อมีข้อมูลครบทั้ง 2 Streams ---
              final categories = categorySnapshot.data ?? [];
              final transactions = transactionSnapshot.data?.docs ?? [];

              if (transactions.isEmpty) {
                return _buildEmptyStateUI(categories);
              }

              double totalIncome = 0;
              double totalExpense = 0;
              for (var doc in transactions) {
                final data = doc.data() as Map<String, dynamic>;
                final amount = (data['amount'] as num).toDouble();
                if (amount > 0) {
                  totalIncome += amount;
                } else {
                  totalExpense += amount;
                }
              }
              final double totalBalance = totalIncome + totalExpense;
              final List<CategoryExpense> categoryExpenses = _getCategoryExpenses(transactions, categories);

              return _buildMainUI(totalBalance, totalExpense.abs(), transactions, categoryExpenses, categories);
            },
          );
        },
      ),
    );
  }

  /// ✅ 8. ปรับปรุง UI หลักให้รับ List<Category>
  Widget _buildMainUI(double balance, double expense, List<QueryDocumentSnapshot> transactions, List<CategoryExpense> categoryExpenses, List<Category> categories) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HeaderWidget(userProfileStream: _userProfileStream),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: BalanceCardWidget(balance: balance, totalExpense: expense),
                ),
                const SizedBox(width: 8),
                if (categoryExpenses.isNotEmpty)
                  Expanded(
                    child: ExpenseBarChart(data: categoryExpenses),
                  ),
              ],
            ),
          ),
          // ✅ ส่ง List<Category> เข้าไปโดยตรง
          CategoriesGridWidget(categories: categories),
          // ⚠️ หมายเหตุ: คุณต้องไปแก้ไข RecentTransactionsList ให้รับ List<Category> ด้วย
          RecentTransactionsList(
            transactions: transactions,
            categories: categories,
          ),
        ],
      ),
    );
  }

  /// ✅ 9. ปรับปรุง UI ตอนไม่มีข้อมูลให้รับ List<Category>
  Widget _buildEmptyStateUI(List<Category> categories) {
    return SingleChildScrollView(
      child: Column(
        children: [
          HeaderWidget(userProfileStream: _userProfileStream),
          const BalanceCardWidget(balance: 0, totalExpense: 0),
          CategoriesGridWidget(categories: categories),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('รายการล่าสุด', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
                Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Text("ยังไม่มีรายการ..."),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}