import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:run_android/Screen/Pages/HomePage/widgets/balance_card_widget.dart';
import 'package:run_android/Screen/Pages/HomePage/widgets/categories_grid_widget.dart';
import 'package:run_android/Screen/Pages/HomePage/widgets/expense_bar_chart.dart';
import 'package:run_android/Screen/Pages/HomePage/widgets/header_widget.dart';
import 'package:run_android/Screen/Pages/HomePage/widgets/recent_transactions_list.dart';

// ✅ 1. Import Service และ Model ที่จำเป็นทั้งหมด
import 'package:run_android/services/categories_service.dart';
import 'package:run_android/models/category_model.dart';



class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final User? user = FirebaseAuth.instance.currentUser;
  final CategoryService _categoryService = CategoryService();

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
      
      _categoriesStream = _categoryService.getAllCategoriesForUser();
    }
  }

  List<CategoryExpense> _getCategoryExpenses(List<QueryDocumentSnapshot> transactions, List<Category> categories) {
    Map<String, double> categoryExpenseMap = {};
    Map<String, Color> categoryColorMap = {};
    final List<Color> predefinedColors = [
      Colors.lightBlueAccent.shade200, Colors.pinkAccent.shade100, Colors.tealAccent.shade400, Colors.orangeAccent.shade200, Colors.purpleAccent.shade100,
      Colors.greenAccent.shade400, Colors.redAccent.shade100, Colors.indigoAccent.shade100, Colors.amber.shade300, Colors.cyan.shade300,
    ];
    int colorIndex = 0;

    for (var cat in categories) {
      categoryExpenseMap[cat.name] = 0.0;
      categoryColorMap[cat.name] = predefinedColors[colorIndex % predefinedColors.length];
      colorIndex++;
    }

    for (var doc in transactions) {
      final data = doc.data() as Map<String, dynamic>;
      final amount = (data['amount'] as num).toDouble();
      final categoryName = data['categoryName'] as String? ?? 'ไม่ระบุหมวดหมู่';

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
      body: StreamBuilder<List<Category>>(
        stream: _categoriesStream,
        builder: (context, categorySnapshot) {
          return StreamBuilder<QuerySnapshot>(
            stream: _transactionsStream,
            builder: (context, transactionSnapshot) {
              
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

  Widget _buildMainUI(double balance, double expense, List<QueryDocumentSnapshot> transactions, List<CategoryExpense> categoryExpenses, List<Category> categories) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HeaderWidget(userProfileStream: _userProfileStream),
          const SizedBox(height: 8),
          
          // ✅ เรียกใช้ BalanceCardWidget ที่อัปเดตแล้ว
          BalanceCardWidget(
            balance: balance,
            totalExpense: expense,
            expenseData: categoryExpenses,
          ),
          
          CategoriesGridWidget(categories: categories),
          RecentTransactionsList(
            transactions: transactions,
            categories: categories,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyStateUI(List<Category> categories) {
    return SingleChildScrollView(
      child: Column(
        children: [
          HeaderWidget(userProfileStream: _userProfileStream),
          const SizedBox(height: 8),
          
          // ✅ เรียกใช้ BalanceCardWidget ตอนไม่มีข้อมูล
          const BalanceCardWidget(
            balance: 0, 
            totalExpense: 0,
            expenseData: [], // ส่ง list ว่างเข้าไป
          ),

          CategoriesGridWidget(categories: categories),
          // ... (ส่วน UI ที่เหลือ)
        ],
      ),
    );
  }
}