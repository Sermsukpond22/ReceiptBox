import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('หน้าหลัก'),
        backgroundColor: Colors.blue,
      ),
      body: Center(
        child: Text(
          'ยินดีต้อนรับสู่หน้าหลัก!',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
