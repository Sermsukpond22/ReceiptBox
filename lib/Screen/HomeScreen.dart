import 'package:flutter/material.dart';
import 'package:run_android/Screen/Pages/ReceiptPage.dart/AddReceipt_page.dart';
import 'package:run_android/Screen/Pages/chat_page.dart';
import 'package:run_android/Screen/Pages/Category_manage/category_page.dart';
import 'package:run_android/Screen/Pages/home_page.dart';
import 'package:run_android/Screen/Pages/ProfilePage/profile_page.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;



  final List<Widget> _pages = [
    HomePage(),
    CategoryPage(),
    AddReceiptPage(),
    ChatPage(),
    ProfilePage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _onAddDocument() {
    setState(() {
      _selectedIndex = 2;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      floatingActionButton: FloatingActionButton(
        onPressed: _onAddDocument,
        backgroundColor: Colors.blueAccent,
        tooltip: 'เพิ่มเอกสาร',
        child: Icon(Icons.add, size: 32),
        elevation: 8,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: CircularNotchedRectangle(),
        notchMargin: 8,
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // ซ้าย
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.home, color: _selectedIndex == 0 ? Colors.blue : Colors.grey),
                    onPressed: () => _onItemTapped(0),
                  ),
                  IconButton(
                    icon: Icon(Icons.folder, color: _selectedIndex == 1 ? Colors.blue : Colors.grey),
                    onPressed: () => _onItemTapped(1),
                  ),
                ],
              ),
              // ขวา
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.chat_bubble, color: _selectedIndex == 3 ? Colors.blue : Colors.grey),
                    onPressed: () => _onItemTapped(3),
                  ),
                  IconButton(
                    icon: Icon(Icons.person, color: _selectedIndex == 4 ? Colors.blue : Colors.grey),
                    onPressed: () => _onItemTapped(4),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
