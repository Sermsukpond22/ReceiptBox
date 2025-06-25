import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';

class VisionOCRService {
  static Future<String> scanTextFromImage(File imageFile) async {
    final apiKey = dotenv.env['GOOGLE_VISION_API_KEY'];
    final url = Uri.parse(
        'https://vision.googleapis.com/v1/images:annotate?key=$apiKey');

    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);

    final requestPayload = {
      "requests": [
        {
          "image": {
            "content": base64Image,
          },
          "features": [
            {
              "type": "TEXT_DETECTION",
            }
          ]
        }
      ]
    };

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: json.encode(requestPayload),
    );

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      final textAnnotations = jsonResponse['responses'][0]['textAnnotations'];
      if (textAnnotations != null && textAnnotations.isNotEmpty) {
        return textAnnotations[0]['description'];
      } else {
        return 'ไม่พบข้อความในภาพ';
      }
    } else {
      throw Exception('OCR ผิดพลาด: ${response.body}');
    }
  }

  static double? extractAmount(String text) {
    final RegExp amountRegex = RegExp(r'(\d+[.,]?\d{0,2})');
    final matches = amountRegex.allMatches(text);

    if (matches.isNotEmpty) {
      // เอาตัวเลขที่มากที่สุด (น่าจะเป็นราคารวม)
      final amounts = matches.map((m) => double.tryParse(m.group(1)!.replaceAll(',', '')) ?? 0).toList();
      return amounts.reduce((a, b) => a > b ? a : b);
    }
    return null;
  }

  static DateTime? extractDate(String text) {
    final RegExp dateRegex = RegExp(
      r'(\d{1,2}/\d{1,2}/\d{2,4})|(\d{4}-\d{2}-\d{2})',
    );

    final match = dateRegex.firstMatch(text);
    if (match != null) {
      try {
        return DateFormat('dd/MM/yyyy').parse(match.group(0)!);
      } catch (_) {
        try {
          return DateFormat('yyyy-MM-dd').parse(match.group(0)!);
        } catch (_) {}
      }
    }
    return null;
  }
}
