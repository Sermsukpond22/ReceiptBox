import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:run_android/Screen/Pages/%E0%B9%87HomePage/widgets/balance_card_widget.dart';
import 'package:run_android/Screen/Pages/%E0%B9%87HomePage/widgets/categories_grid_widget.dart';
import 'package:run_android/Screen/Pages/%E0%B9%87HomePage/widgets/expense_bar_chart.dart';
import 'package:run_android/Screen/Pages/%E0%B9%87HomePage/widgets/header_widget.dart';
import 'package:run_android/Screen/Pages/%E0%B9%87HomePage/widgets/recent_transactions_list.dart';



class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? user = FirebaseAuth.instance.currentUser;

  Stream<QuerySnapshot>? _transactionsStream;
  late Stream<DocumentSnapshot> _userProfileStream;
  List<Map<String, dynamic>> _categories = [];

  @override
  void initState() {
    super.initState();
    if (user != null) {
      _transactionsStream = _firestore
          .collection('receipts')
          .where('userId', isEqualTo: user!.uid)
          .orderBy('transactionDate', descending: true)
          .snapshots();

      _userProfileStream =
          _firestore.collection('users').doc(user!.uid).snapshots();

      _fetchCategories();
    }
  }

  Future<void> _fetchCategories() async {
    if (user == null) return;
    try {
      final userCategoriesQuery = _firestore
          .collection('categories')
          .where('userId', isEqualTo: user!.uid);
      final defaultCategoriesQuery = _firestore
          .collection('categories')
          .where('userId', isNull: true);

      final userCategoriesSnapshot = await userCategoriesQuery.get();
      final defaultCategoriesSnapshot = await defaultCategoriesQuery.get();

      final List<Map<String, dynamic>> fetchedCategories = [];
      for (var doc in defaultCategoriesSnapshot.docs) {
        fetchedCategories.add({'id': doc.id, ...doc.data()});
      }
      for (var doc in userCategoriesSnapshot.docs) {
        fetchedCategories.add({'id': doc.id, ...doc.data()});
      }

      fetchedCategories.sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));

      if (mounted) {
        setState(() {
          _categories = fetchedCategories;
        });
      }
    } catch (e) {
      print('Error fetching categories: $e');
    }
  }

  /// Function to calculate category-wise expenses for the chart
  List<CategoryExpense> _getCategoryExpenses(List<QueryDocumentSnapshot> transactions) {
    Map<String, double> categoryExpenseMap = {};
    Map<String, Color> categoryColorMap = {}; // To store colors for categories

    // Initialize category colors (you might want a more robust way to assign colors)
    final List<Color> predefinedColors = [
      Colors.blue, Colors.red, Colors.green, Colors.orange, Colors.purple,
      Colors.teal, Colors.brown, Colors.pink, Colors.indigo, Colors.amber,
    ];
    int colorIndex = 0;

    // Populate category names and initial colors
    for (var cat in _categories) {
      final categoryName = cat['name'] as String;
      categoryExpenseMap[categoryName] = 0.0;
      categoryColorMap[categoryName] = predefinedColors[colorIndex % predefinedColors.length];
      colorIndex++;
    }


    for (var doc in transactions) {
      final data = doc.data() as Map<String, dynamic>;
      final amount = (data['amount'] as num).toDouble();
      final categoryName = data['category'] as String? ?? 'ไม่ระบุหมวดหมู่';

      // Only consider expenses (negative amounts)
      if (amount < 0) {
        categoryExpenseMap.update(
          categoryName,
          (value) => value + amount.abs(), // Add absolute value to sum expenses
          ifAbsent: () => amount.abs(), // If category not in _categories (e.g., old data), add it
        );

        // Assign a color if it's a new category not in predefined list
        if (!categoryColorMap.containsKey(categoryName)) {
            categoryColorMap[categoryName] = predefinedColors[colorIndex % predefinedColors.length];
            colorIndex++;
        }
      }
    }

    // Convert map to list of CategoryExpense objects
    List<CategoryExpense> categoryExpenses = [];
    categoryExpenseMap.forEach((name, amount) {
      if (amount > 0) { // Only add categories with actual expenses
        categoryExpenses.add(CategoryExpense(name, amount, categoryColorMap[name]!));
      }
    });

    // Sort by amount in descending order for the chart
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
      body: StreamBuilder<QuerySnapshot>(
        stream: _transactionsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyStateUI();
          }

          final transactions = snapshot.data!.docs;
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

          // Prepare data for the bar chart
          final List<CategoryExpense> categoryExpenses = _getCategoryExpenses(transactions);

          return _buildMainUI(totalBalance, totalExpense.abs(), transactions, categoryExpenses);
        },
      ),
    );
  }

  // Updated _buildMainUI to arrange BalanceCardWidget and ExpenseBarChart side-by-side
  Widget _buildMainUI(double balance, double expense, List<QueryDocumentSnapshot> transactions, List<CategoryExpense> categoryExpenses) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HeaderWidget(userProfileStream: _userProfileStream),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row( // ✅ ใช้ Row เพื่อจัดเรียง widget แบบแนวนอน
              crossAxisAlignment: CrossAxisAlignment.start, // จัดให้เริ่มต้นจากด้านบน
              children: [
                Expanded( // ✅ BalanceCardWidget ใช้ครึ่งจอ
                  child: BalanceCardWidget(balance: balance, totalExpense: expense),
                ),
                const SizedBox(width: 8), // ระยะห่างระหว่าง widget
                if (categoryExpenses.isNotEmpty) // ✅ ExpenseBarChart ใช้ครึ่งจอ (ถ้ามีข้อมูล)
                  Expanded(
                    child: ExpenseBarChart(data: categoryExpenses),
                  ),
              ],
            ),
          ),
          CategoriesGridWidget(categories: _categories),
          RecentTransactionsList(
            transactions: transactions,
            categories: _categories,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyStateUI() {
    return SingleChildScrollView(
      child: Column(
        children: [
          HeaderWidget(userProfileStream: _userProfileStream),
          const BalanceCardWidget(balance: 0, totalExpense: 0), // Updated to only pass totalExpense
          CategoriesGridWidget(categories: _categories),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('รายการล่าสุด', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    TextButton(onPressed: () {}, child: const Text('ดูทั้งหมด')),
                  ],
                ),
                const Center(
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
