import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'chat_logs_service.dart';  // เพิ่มการนำเข้า ChatLogsService

class GeminiService {
  final String _apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
  final ChatLogsService _chatLogsService = ChatLogsService(); // สร้างอินสแตนซ์ของ ChatLogsService

  Future<String> getGeminiResponse(String userId, String userMessage) async {
    if (_apiKey.isEmpty) {
      return '❗ ไม่พบ API Key (GEMINI_API_KEY)';
    }

    final endpoint = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$_apiKey';

    try {
      final response = await http.post(
        Uri.parse(endpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [
            {
              "role": "user", // ✅ ต้องมี role
              "parts": [
                {"text": userMessage}
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);

        try {
          // ดึงคำตอบจาก Gemini API
          String geminiResponse = decoded['candidates'][0]['content']['parts'][0]['text'] ?? '❓ ไม่พบคำตอบ';

          // บันทึกข้อมูลการแชทลงใน Firebase
          await _chatLogsService.logChat(
            userId: userId,
            message: userMessage,
            response: geminiResponse,
          );

          return geminiResponse;
        } catch (e) {
          print('❗ รูปแบบ response ไม่ถูกต้อง: $e');
          print('📦 response: $decoded');
          return '❗ ตอบกลับจาก Gemini ไม่อยู่ในรูปแบบที่คาดไว้';
        }
      } else {
        print('❗ Gemini API error: ${response.statusCode} - ${response.body}');
        return '❗ เกิดข้อผิดพลาดจาก Gemini API (${response.statusCode})';
      }
    } catch (e) {
      print('❗ ข้อผิดพลาด HTTP: $e');
      return '❗ ไม่สามารถเชื่อมต่อกับ Gemini ได้';
    }
  }
}
