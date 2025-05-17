import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:run_android/Screen/HomeScreen.dart';
import 'package:run_android/Screen/LoginScreen.dart';
import 'package:run_android/Screen/OnboardingScreen.dart';
import 'package:run_android/Screen/SplashScreen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
// เพิ่ม import

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await Firebase.initializeApp(); // เริ่มต้น Firebase
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        textTheme: GoogleFonts.kanitTextTheme(),
      ),
      initialRoute: '/splash', // เริ่มที่ Onboarding
      routes: {
        '/splash': (context) => SplashScreen(),
        '/onboarding': (context) => OnboardingScreen(),
        '/login': (context) => LoginScreen(), // แก้ชื่อให้ตรงกับไฟล์ของคุณ
        '/home': (context) => HomeScreen(), 
        
        
      },
    );
  }
}


