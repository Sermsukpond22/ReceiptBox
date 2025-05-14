import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:run_android/services/chat_logs_service.dart';

class GeminiService {
  final String _apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
  final ChatLogsService _chatLogsService = ChatLogsService();

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
              "role": "user",
              "parts": [
                {"text": userMessage}
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        String geminiResponse = decoded['candidates'][0]['content']['parts'][0]['text'] ?? '❓ ไม่พบคำตอบ';

        await _chatLogsService.logChat(
          userId: userId,
          message: userMessage,
          response: geminiResponse,
        );

        return geminiResponse;
      } else {
        return '❗ เกิดข้อผิดพลาดจาก Gemini API (${response.statusCode})';
      }
    } catch (e) {
      return '❗ ไม่สามารถเชื่อมต่อกับ Gemini ได้';
    }
  }
}
