import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? user = FirebaseAuth.instance.currentUser;

  Stream<QuerySnapshot>? _receiptsStream;
  late Stream<DocumentSnapshot> _userProfileStream;
  List<Map<String, dynamic>> _categories = []; // State สำหรับเก็บข้อมูลหมวดหมู่

  @override
  void initState() {
    super.initState();
    if (user != null) {
      _receiptsStream = _firestore
          .collection('receipts')
          .where('userId', isEqualTo: user!.uid)
          .orderBy('transactionDate', descending: true)
          .snapshots();

      _userProfileStream = _firestore
          .collection('users')
          .doc(user!.uid)
          .snapshots();

      _fetchCategories(); // เรียกใช้เมธอดดึงหมวดหมู่
    }
  }

  // เมธอดสำหรับดึงข้อมูลหมวดหมู่จาก Firestore
  // ตอนนี้จะดึงทั้งหมวดหมู่ของผู้ใช้และหมวดหมู่ที่เป็น Default (userId == null)
  Future<void> _fetchCategories() async {
    try {
      // Query สำหรับหมวดหมู่ของผู้ใช้ปัจจุบัน
      final userCategoriesQuery = _firestore
          .collection('categories')
          .where('userId', isEqualTo: user!.uid);

      // Query สำหรับหมวดหมู่ที่เป็น Default (userId == null)
      final defaultCategoriesQuery = _firestore
          .collection('categories')
          .where('userId', isNull: true);

      // ดึงข้อมูลจากทั้งสอง Query
      final userCategoriesSnapshot = await userCategoriesQuery.get();
      final defaultCategoriesSnapshot = await defaultCategoriesQuery.get();

      // รวมผลลัพธ์
      final List<Map<String, dynamic>> fetchedCategories = [];

      // เพิ่มหมวดหมู่ Default ก่อน
      for (var doc in defaultCategoriesSnapshot.docs) {
        fetchedCategories.add({
          ...doc.data() as Map<String, dynamic>,
          'id': doc.id,
        });
      }

      // เพิ่มหมวดหมู่ของผู้ใช้
      for (var doc in userCategoriesSnapshot.docs) {
        fetchedCategories.add({
          ...doc.data() as Map<String, dynamic>,
          'id': doc.id,
        });
      }

      // เรียงลำดับตาม name เพื่อให้ default category อยู่ก่อน หรือตามที่คุณต้องการ
      fetchedCategories.sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));


      setState(() {
        _categories = fetchedCategories;
      });
    } catch (e) {
      print('Error fetching categories: $e');
      // สามารถเพิ่มการจัดการข้อผิดพลาด เช่น แสดง SnackBar
    }
  }

  String _formatCurrency(double amount) {
    final format = NumberFormat.currency(locale: 'th_TH', symbol: '฿');
    return format.format(amount);
  }

  String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    final format = DateFormat('d MMM yy', 'th_TH');
    return format.format(date);
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text("กรุณาเข้าสู่ระบบ"),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: StreamBuilder<QuerySnapshot>(
        stream: _receiptsStream,
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

          final receipts = snapshot.data!.docs;
          double totalIncome = 0;
          double totalExpense = 0;

          for (var doc in receipts) {
            final data = doc.data() as Map<String, dynamic>;
            final amount = (data['amount'] as num).toDouble();
            if (amount > 0) {
              totalIncome += amount;
            } else {
              totalExpense += amount;
            }
          }
          final double totalBalance = totalIncome + totalExpense;

          return _buildMainUI(totalBalance, totalIncome, totalExpense, receipts);
        },
      ),
      // FloatingActionButton ถูกนำออกแล้ว
    );
  }

  Widget _buildMainUI(double balance, double income, double expense, List<QueryDocumentSnapshot> receipts) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          _buildBalanceCard(balance, income, expense.abs()),
          _buildCategoriesGrid(), // แสดงหมวดหมู่
          _buildRecentTransactions(receipts),
        ],
      ),
    );
  }

  Widget _buildEmptyStateUI() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildHeader(),
          _buildBalanceCard(0, 0, 0),
          _buildCategoriesGrid(), // แสดงหมวดหมู่
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('รายการล่าสุด', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                TextButton(onPressed: () {}, child: const Text('ดูทั้งหมด')),
              ],
            ),
          ),
          const Center(child: Padding(
            padding: EdgeInsets.all(32.0),
            child: Text("ยังไม่มีรายการ..."),
          )),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return StreamBuilder<DocumentSnapshot>(
      stream: _userProfileStream,
      builder: (context, snapshot) {
        String displayName = 'ผู้ใช้';
        String profileImageUrl = user?.photoURL ?? 'https://i.pravatar.cc/150?u=a042581f4e29026704d';

        if (snapshot.connectionState == ConnectionState.active && snapshot.hasData) {
          final userData = snapshot.data!.data() as Map<String, dynamic>?;
          if (userData != null) {
            displayName = userData['FullName'] ?? 'ผู้ใช้';
            profileImageUrl = userData['ProfileImage'] ?? profileImageUrl;
          }
        }

        final String welcomeMessage = 'สวัสดี, คุณ$displayName';

        return Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 60.0, 16.0, 20.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundImage: NetworkImage(profileImageUrl),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      welcomeMessage,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      DateFormat('EEEE, d MMMM Thoroughbred', 'th_TH').format(DateTime.now()),
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  // เพิ่ม Logic เมื่อกดปุ่ม Notification
                },
                icon: const Icon(Icons.notifications_none, size: 28),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBalanceCard(double balance, double income, double expense) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        padding: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            colors: [Color(0xFF007BFF), Color(0xFF0056B3)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ยอดเงินคงเหลือทั้งหมด',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              _formatCurrency(balance),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSummaryItem(Icons.arrow_upward, 'รายรับ', _formatCurrency(income)),
                _buildSummaryItem(Icons.bar_chart, 'สรุปยอดค่าใช้จ่าย', null),
                _buildSummaryItem(Icons.arrow_downward, 'รายจ่าย', _formatCurrency(expense)),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(IconData icon, String title, String? amount) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 4),
        Text(title, style: const TextStyle(color: Colors.white70, fontSize: 14)),
        if (amount != null)
          Text(amount, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildCategoriesGrid() {
    if (_categories.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(
          child: Text('ยังไม่มีหมวดหมู่ให้แสดง'),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'หมวดหมู่',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.8,
            ),
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final category = _categories[index];
              final categoryName = category['name'] as String? ?? 'ไม่ระบุ';
              final String? iconName = category['iconName'] as String?;
              final IconData categoryIcon = _getIconData(iconName);

              return GestureDetector(
                onTap: () {
                  print('Selected category: $categoryName');
                  // สามารถเพิ่ม logic สำหรับการเลือกหมวดหมู่ที่นี่
                },
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.blue.withOpacity(0.1),
                      child: Icon(categoryIcon, color: Colors.blue),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      categoryName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  IconData _getIconData(String? iconName) {
    switch (iconName) {
      case 'restaurant_menu':
        return Icons.restaurant_menu;
      case 'shopping_cart':
        return Icons.shopping_cart;
      case 'fastfood':
        return Icons.fastfood;
      case 'home':
        return Icons.home;
      case 'directions_bus':
        return Icons.directions_bus;
      case 'medical_services':
        return Icons.medical_services;
      case 'school':
        return Icons.school;
      case 'movie':
        return Icons.movie;
      case 'fitness_center':
        return Icons.fitness_center;
      case 'phone_android':
        return Icons.phone_android;
      case 'lightbulb':
        return Icons.lightbulb;
      case 'water_drop':
        return Icons.water_drop;
      case 'wifi':
        return Icons.wifi;
      case 'credit_card':
        return Icons.credit_card;
      case 'flight':
        return Icons.flight;
      case 'local_gas_station':
        return Icons.local_gas_station;
      case 'pets':
        return Icons.pets;
      case 'book':
        return Icons.book;
      case 'celebration':
        return Icons.celebration;
      case 'work':
        return Icons.work;
      case 'toys':
        return Icons.toys;
      case 'car_rental':
        return Icons.car_rental;
      case 'local_laundry_service':
        return Icons.local_laundry_service;
      case 'palette':
        return Icons.palette;
      case 'attach_money':
        return Icons.attach_money;
      case 'build':
        return Icons.build;
      case 'business_center':
        return Icons.business_center;
      case 'electric_car':
        return Icons.electric_car;
      case 'vpn_key':
        return Icons.vpn_key;
      case 'child_friendly':
        return Icons.child_friendly;
      case 'casino':
        return Icons.casino;
      case 'spa':
        return Icons.spa;
      case 'sports_esports':
        return Icons.sports_esports;
      case 'music_note':
        return Icons.music_note;
      case 'camera_alt':
        return Icons.camera_alt;
      case 'shopping_bag':
        return Icons.shopping_bag;
      case 'storefront':
        return Icons.storefront;
      case 'receipt':
        return Icons.receipt;
      case 'commute':
        return Icons.commute;
      default:
        return Icons.category; // Icon default หากไม่พบ
    }
  }

  Widget _buildRecentTransactions(List<QueryDocumentSnapshot> receipts) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('รายการล่าสุด', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              TextButton(onPressed: () {
                // เพิ่ม Logic เมื่อกดดูทั้งหมด
              }, child: const Text('ดูทั้งหมด')),
            ],
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: receipts.length > 5 ? 5 : receipts.length,
            itemBuilder: (context, index) {
              final doc = receipts[index];
              final data = doc.data() as Map<String, dynamic>;
              final storeName = data['storeName'] ?? 'ไม่มีชื่อร้าน';
              final amount = (data['amount'] as num).toDouble();
              final date = data['transactionDate'] as Timestamp;
              final categoryNameFromReceipt = data['category'] as String? ?? 'default';

              final categoryMatch = _categories.firstWhere(
                (cat) => cat['name'] == categoryNameFromReceipt,
                orElse: () => {'iconName': 'receipt'}, // icon default หากไม่พบ category
              );
              final IconData icon = _getIconData(categoryMatch['iconName']);

              return Card(
                elevation: 0,
                color: Colors.white,
                margin: const EdgeInsets.symmetric(vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: amount < 0 ? Colors.red[50] : Colors.green[50],
                    child: Icon(icon, color: amount < 0 ? Colors.red : Colors.green),
                  ),
                  title: Text(storeName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(_formatDate(date)),
                  trailing: Text(
                    _formatCurrency(amount),
                    style: TextStyle(
                      color: amount < 0 ? Colors.red : Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}