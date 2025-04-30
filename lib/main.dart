import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:run_android/LoginScreen.dart';
import 'package:run_android/OnboardingScreen.dart';
import 'package:run_android/SplashScreen.dart';
// เพิ่ม import

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // เริ่มต้น Firebase
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      initialRoute: '/splash', // เริ่มที่ Onboarding
      routes: {
        '/splash': (context) => SplashScreen(),
        '/onboarding': (context) => OnboardingScreen(),
        '/login': (context) => LoginScreen(), // แก้ชื่อให้ตรงกับไฟล์ของคุณ
        
      },
    );
  }
}
