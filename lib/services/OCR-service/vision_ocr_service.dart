// services/google_vision_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:run_android/services/OCR-service/receipt_ocr_result.dart';
import 'package:run_android/services/OCR-service/receipt_text_analyzer.dart';

class GoogleVisionService {
  // Google Cloud Vision API configuration
  static const String _baseUrl = 'https://vision.googleapis.com/v1/images:annotate';
  
  // ดึง API Key จาก .env file
  static String get _apiKey {
    final apiKey = dotenv.env['GOOGLE_VISION_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('GOOGLE_VISION_API_KEY not found in .env file');
    }
    return apiKey;
  }
  
  // Singleton pattern
  static final GoogleVisionService _instance = GoogleVisionService._internal();
  factory GoogleVisionService() => _instance;
  GoogleVisionService._internal();

  /// สแกนใบเสร็จและดึงข้อมูลออกมา
  Future<ReceiptOCRResult> scanReceipt(File imageFile) async {
    try {
      // อ่านไฟล์รูปภาพและแปลงเป็น base64
      final imageBytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(imageBytes);
      
      // สร้าง request body สำหรับ Vision API
      final requestBody = _buildVisionApiRequest(base64Image);
      
      // เรียก Google Vision API
      final response = await _callVisionApi(requestBody);
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        // แปลงผลลัพธ์จาก API เป็นข้อมูลใบเสร็จ
        return _parseReceiptData(responseData);
      } else {
        throw Exception('Vision API Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to scan receipt: $e');
    }
  }

  /// สร้าง request body สำหรับ Google Vision API
  Map<String, dynamic> _buildVisionApiRequest(String base64Image) {
    return {
      'requests': [
        {
          'image': {
            'content': base64Image,
          },
          'features': [
            {
              'type': 'TEXT_DETECTION',
              'maxResults': 50,
            },
            {
              'type': 'DOCUMENT_TEXT_DETECTION',
              'maxResults': 50,
            }
          ],
          'imageContext': {
            'languageHints': ['th', 'en'], // รองรับภาษาไทยและอังกฤษ
          }
        }
      ]
    };
  }

  /// เรียก Google Vision API
  Future<http.Response> _callVisionApi(Map<String, dynamic> requestBody) async {
    final url = Uri.parse('$_baseUrl?key=$_apiKey');
    
    return await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode(requestBody),
    );
  }

  /// แปลงผลลัพธ์จาก Vision API เป็นข้อมูลใบเสร็จ
  ReceiptOCRResult _parseReceiptData(Map<String, dynamic> responseData) {
    try {
      // ดึงข้อความทั้งหมดจาก response
      final responses = responseData['responses'] as List?;
      if (responses == null || responses.isEmpty) {
        return ReceiptOCRResult.empty();
      }

      final textAnnotations = responses[0]['textAnnotations'] as List?;
      if (textAnnotations == null || textAnnotations.isEmpty) {
        return ReceiptOCRResult.empty();
      }

      // ดึงข้อความทั้งหมด
      final fullText = textAnnotations[0]['description'] as String? ?? '';
      
      // แยกข้อความเป็นบรรทัด
      final lines = fullText.split('\n').map((line) => line.trim()).toList();
      final cleanLines = lines.where((line) => line.isNotEmpty).toList();

      // วิเคราะห์ข้อมูลจากข้อความ
      return _analyzeReceiptText(cleanLines);
    } catch (e) {
      throw Exception('Failed to parse receipt data: $e');
    }
  }

  /// วิเคราะห์ข้อมูลจากข้อความที่สแกนได้
  ReceiptOCRResult _analyzeReceiptText(List<String> lines) {
    final analyzer = ReceiptTextAnalyzer();
    
    return ReceiptOCRResult(
      storeName: analyzer.extractStoreName(lines),
      amount: analyzer.extractAmount(lines),
      date: analyzer.extractDate(lines),
      description: analyzer.extractDescription(lines),
      rawText: lines.join('\n'),
      confidence: analyzer.calculateConfidence(lines),
    );
  }
}