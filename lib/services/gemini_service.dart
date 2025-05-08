import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GeminiService {
  final String _apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';

  Future<String> getGeminiResponse(String userMessage) async {
    final endpoint = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent';

    final response = await http.post(
      Uri.parse('$endpoint?key=$_apiKey'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "contents": [
          {
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
        return decoded['candidates'][0]['content']['parts'][0]['text'] ?? '❓ ไม่พบคำตอบ';
      } catch (e) {
        return '❗ ตอบกลับจาก Gemini ไม่อยู่ในรูปแบบที่คาดไว้';
      }
    } else {
      throw Exception('Gemini API error: ${response.body}');
    }
  }
}
