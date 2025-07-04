import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:run_android/Screen/HomeScreen.dart';
import 'package:run_android/Screen/LoginScreen.dart';
import 'package:run_android/Screen/OnboardingScreen.dart';
import 'package:run_android/Screen/Pages/ReceiptPage.dart/AddReceipt_page.dart';
import 'package:run_android/Screen/Pages/chat_page.dart';
import 'package:run_android/Screen/Pages/Category_manage/category_page.dart';
import 'package:run_android/Screen/Pages/ProfilePage/profile_page.dart';
import 'package:run_android/Screen/SplashScreen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart'; // เพิ่ม import นี้

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await Firebase.initializeApp(); // เริ่มต้น Firebase

  // ***************************************************************
  // ส่วนสำคัญ: เรียกใช้ initializeDateFormatting() เพื่อเริ่มต้นข้อมูลภาษา
  // เราจะเริ่มต้นสำหรับภาษาไทย ('th')
  // ***************************************************************
  await initializeDateFormatting('th', null);

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Receipt Box',
      theme: ThemeData(
        // ***************************************************************
        // ส่วนสำคัญ: กำหนด ColorScheme เพื่อควบคุมสีทั่วทั้งแอป
        // ***************************************************************
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue, // ใช้สีน้ำเงินเป็น "เมล็ด" หลัก
          primary: Colors.blue, // สีหลักของแอป
          onPrimary: Colors.white, // สีข้อความ/ไอคอนบนสี primary
          secondary: Colors.blueAccent, // สีรอง (ใช้กับ FloatingActionButton)
          onSecondary: Colors.white, // สีข้อความ/ไอคอนบนสี secondary
          // กำหนดสีพื้นหลังหลักของ Scaffold ให้เป็นสีฟ้าอ่อน
          background: Colors.blue[50]!, // พื้นหลังของ body ใน Scaffold
          onBackground: Colors.black87, // สีข้อความบนพื้นหลัง
          surface: Colors.white, // สีของ Card, Dialog, BottomAppBar
          onSurface: Colors.black87, // สีข้อความบนพื้นผิว
          error: Colors.red,
          onError: Colors.white,
        ),

        // กำหนดสีพื้นหลัง Scaffold ทั่วไปให้เป็นสีฟ้าอ่อน
        // ค่านี้จะถูกใช้เป็นค่าเริ่มต้นสำหรับพื้นหลังของ Scaffold
        scaffoldBackgroundColor: Colors.grey[50], // กำหนดตรงนี้!

        // ตั้งค่า AppBar ทั่วไป
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.blue, // ตั้งค่า AppBar ให้เป็นสีน้ำเงิน
          foregroundColor: Colors.black, // สีของ title และไอคอนใน AppBar
          elevation: 4.0, // เพิ่มเงาเล็กน้อย
          titleTextStyle: GoogleFonts.prompt(fontWeight: FontWeight.w600, fontSize: 20, color: Colors.black),
          centerTitle: true, // จัด title ให้อยู่ตรงกลาง
        ),

        // ตั้งค่า ElevatedButton ทั่วไป
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue, // สีปุ่มหลัก
            foregroundColor: Colors.white, // สีข้อความบนปุ่มหลัก
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            minimumSize: Size(double.infinity, 50),
            textStyle: GoogleFonts.prompt(fontSize: 16, fontWeight: FontWeight.bold),
            elevation: 2.0, // เพิ่มเงาเล็กน้อย
          ),
        ),

        // ตั้งค่า InputDecoration (สำหรับ TextField) ทั่วไป
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.white, // พื้นหลังของ TextField เป็นสีขาว
          labelStyle: GoogleFonts.prompt(color: Colors.grey[700]),
          prefixIconColor: Colors.grey[700], // สีของไอคอนนำหน้า
          floatingLabelStyle: GoogleFonts.prompt(color: Colors.blue[700], fontWeight: FontWeight.w600),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.blue.shade700, width: 2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade400), // สีขอบเมื่อปกติ
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300), // สีขอบเมื่อ disabled
          ),
        ),

        // กำหนด font ทั่วทั้งแอป (ยกเว้นที่กำหนดเองในแต่ละ Widget)
        // คุณสามารถเลือกใช้ Kanit หรือ Prompt เป็น TextTheme หลักได้
        textTheme: GoogleFonts.promptTextTheme(
          Theme.of(context).textTheme, // ผสมผสานกับ TextTheme Default ของ Flutter
        ),
      ),
      initialRoute: '/login', // ควรเริ่มที่ SplashScreen ก่อน
      routes: {
        '/splash': (context) => SplashScreen(),
        '/onboarding': (context) => OnboardingScreen(),
        '/login': (context) => LoginScreen(),
        '/home': (context) => HomeScreen(),
        '/category': (context) => CategoryPage(),
        '/add_receipt': (context) => AddReceiptPage(),
        '/chatBot': (context) => ChatPage(), 
        '/profile': (context) => ProfilePage(), // เพิ่มเส้นทางสำหรับ ProfilePage
      },
    );
  }
}
