import 'package:flutter/material.dart';

class OnboardingScreen extends StatefulWidget {
  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> onboardingData = [
    {
      "title": "ยินดีต้อนรับ",
      "description": "แอปของเรามีฟีเจอร์มากมายที่ช่วยให้คุณสะดวกสบาย",
      "image": Icons.access_alarm,
    },
    {
      "title": "ใช้งานง่าย",
      "description": "แค่คลิกเดียวก็สามารถใช้งานได้ทันที",
      "image": Icons.touch_app,
    },
    {
      "title": "เริ่มต้นใช้งาน",
      "description": "พร้อมแล้วใช่ไหม? มาเริ่มกันเลย!",
      "image": Icons.start,
    },
  ];

  void _goToLogin(BuildContext context) {
    Navigator.pushReplacementNamed(context, '/login'); // หรือเปลี่ยนตามชื่อ route ของคุณ
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: onboardingData.length,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemBuilder: (context, index) {
              final page = onboardingData[index];
              return OnboardingPage(
                title: page['title'],
                description: page['description'],
                image: page['image'],
              );
            },
          ),
          if (_currentPage == onboardingData.length - 1)
            Positioned(
              bottom: 40,
              left: 20,
              right: 20,
              child: ElevatedButton(
                onPressed: () => _goToLogin(context),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: Colors.blue,
                ),
                child: Text(
                  "เริ่มต้นใช้งาน",
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class OnboardingPage extends StatelessWidget {
  final String title;
  final String description;
  final IconData image;

  OnboardingPage({
    required this.title,
    required this.description,
    required this.image,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(image, size: 150, color: Colors.blue),
          SizedBox(height: 20),
          Text(
            title,
            style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 10),
          Text(
            description,
            style: TextStyle(fontSize: 16, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
