// services/google_vision_service.dart (Complete Enhanced Version)
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';
import 'package:run_android/services/OCR-service/receipt_ocr_result.dart';
import 'package:run_android/services/OCR-service/receipt_text_analyzer.dart';
import 'package:run_android/services/OCR-service/receipt_category_classifier.dart';

class GoogleVisionService {
  // Google Cloud Vision API configuration
  static const String _baseUrl = 'https://vision.googleapis.com/v1/images:annotate';
  static const int _maxImageSize = 10 * 1024 * 1024; // 10MB limit
  static const int _requestTimeoutSeconds = 30;
  
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

  /// สแกนใบเสร็จและดึงข้อมูลออกมา (ปรับปรุงใหม่)
  Future<ReceiptOCRResult> scanReceipt(File imageFile) async {
    try {
      // ตรวจสอบไฟล์
      await _validateImageFile(imageFile);
      
      // อ่านไฟล์รูปภาพและแปลงเป็น base64
      final imageBytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(imageBytes);
      
      // สร้าง request body สำหรับ Vision API
      final requestBody = _buildVisionApiRequest(base64Image);
      
      // เรียก Google Vision API
      final response = await _callVisionApi(requestBody);
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        // ตรวจสอบ error จาก API
        if (responseData['responses'] != null && 
            responseData['responses'][0]['error'] != null) {
          final error = responseData['responses'][0]['error'];
          throw Exception('Vision API Error: ${error['message']}');
        }
        
        // แปลงผลลัพธ์จาก API เป็นข้อมูลใบเสร็จ
        return _parseReceiptData(responseData);
      } else {
        final errorBody = response.body;
        String errorMessage = 'Unknown error';
        
        try {
          final errorData = json.decode(errorBody);
          errorMessage = errorData['error']['message'] ?? 'API request failed';
        } catch (e) {
          errorMessage = 'HTTP ${response.statusCode}: $errorBody';
        }
        
        throw Exception('Vision API Error: $errorMessage');
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Failed to scan receipt: $e');
    }
  }

  /// สแกนและวิเคราะห์ใบเสร็จแบบละเอียด
  Future<Map<String, dynamic>> scanReceiptWithFullAnalysis(File imageFile) async {
    try {
      // สแกนข้อความจาก OCR
      final ocrResult = await scanReceipt(imageFile);
      
      // วิเคราะห์แบบละเอียดพร้อมจำแนกประเภท
      final analyzer = ReceiptTextAnalyzer();
      final lines = ocrResult.rawText.split('\n').map((line) => line.trim()).toList();
      final cleanLines = lines.where((line) => line.isNotEmpty).toList();
      
      final fullAnalysis = analyzer.analyzeReceiptWithCategory(cleanLines);
      
      // สร้างข้อมูลสำหรับฟอร์ม
      final formData = _generateFormData(fullAnalysis);
      
      // สร้างคำแนะนำสำหรับการใช้งาน
      final suggestions = _generateUsageSuggestions(fullAnalysis);
      
      return {
        'ocrResult': ocrResult.toJson(),
        'analysis': fullAnalysis,
        'formData': formData,
        'suggestions': suggestions,
        'processingInfo': {
          'imageSize': await imageFile.length(),
          'processedAt': DateTime.now().toIso8601String(),
          'textLines': cleanLines.length,
          'hasCategory': fullAnalysis['category'] != null,
        },
        'success': true,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {
        'ocrResult': null,
        'analysis': null,
        'formData': null,
        'suggestions': null,
        'processingInfo': null,
        'success': false,
        'error': e.toString(),
        'errorType': _categorizeError(e.toString()),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// ตรวจสอบและทำความสะอาดภาพก่อนส่งไป Vision API
  Future<File?> preprocessImage(File imageFile) async {
    try {
      await _validateImageFile(imageFile);
      
      final fileSize = await imageFile.length();
      
      // หากไฟล์ใหญ่เกินไป อาจต้องลดขนาด
      if (fileSize > _maxImageSize) {
        throw Exception('Image file too large. Maximum size is ${_maxImageSize ~/ (1024 * 1024)}MB');
      }
      
      // ในอนาคตสามารถเพิ่มการปรับขนาดภาพได้ที่นี่
      return imageFile;
    } catch (e) {
      throw Exception('Image preprocessing failed: $e');
    }
  }

  /// ตรวจสอบไฟล์รูปภาพ
  Future<void> _validateImageFile(File imageFile) async {
    if (!await imageFile.exists()) {
      throw Exception('Image file does not exist');
    }
    
    final fileSize = await imageFile.length();
    if (fileSize == 0) {
      throw Exception('Image file is empty');
    }
    
    if (fileSize > _maxImageSize) {
      throw Exception('Image file too large. Maximum size is ${_maxImageSize ~/ (1024 * 1024)}MB');
    }
    
    // ตรวจสอบนามสกุลไฟล์
    final extension = imageFile.path.toLowerCase().split('.').last;
    const allowedExtensions = ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'];
    
    if (!allowedExtensions.contains(extension)) {
      throw Exception('Unsupported image format. Allowed formats: ${allowedExtensions.join(', ')}');
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
              'maxResults': 100,
            },
            {
              'type': 'DOCUMENT_TEXT_DETECTION',
              'maxResults': 100,
            }
          ],
          'imageContext': {
            'languageHints': ['th', 'en'], // รองรับภาษาไทยและอังกฤษ
            'textDetectionParams': {
              'enableTextDetectionConfidenceScore': true
            }
          }
        }
      ]
    };
  }

  /// เรียก Google Vision API
  Future<http.Response> _callVisionApi(Map<String, dynamic> requestBody) async {
    final url = Uri.parse('$_baseUrl?key=$_apiKey');
    
    final client = http.Client();
    try {
      return await client.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'User-Agent': 'Flutter-OCR-Service/1.0',
        },
        body: json.encode(requestBody),
      ).timeout(
        Duration(seconds: _requestTimeoutSeconds),
        onTimeout: () {
          throw Exception('Request timeout after $_requestTimeoutSeconds seconds');
        },
      );
    } finally {
      client.close();
    }
  }

  /// แปลงผลลัพธ์จาก Vision API เป็นข้อมูลใบเสร็จ
  ReceiptOCRResult _parseReceiptData(Map<String, dynamic> responseData) {
    try {
      // ดึงข้อความทั้งหมดจาก response
      final responses = responseData['responses'] as List?;
      if (responses == null || responses.isEmpty) {
        return ReceiptOCRResult.empty();
      }

      final response = responses[0];
      final textAnnotations = response['textAnnotations'] as List?;
      final fullTextAnnotation = response['fullTextAnnotation'];
      
      if (textAnnotations == null || textAnnotations.isEmpty) {
        return ReceiptOCRResult.empty();
      }

      // ดึงข้อความทั้งหมด
      String fullText = '';
      
      if (fullTextAnnotation != null && fullTextAnnotation['text'] != null) {
        // ใช้ fullTextAnnotation ถ้ามี (จะมีการจัดรูปแบบที่ดีกว่า)
        fullText = fullTextAnnotation['text'] as String;
      } else {
        // ใช้ textAnnotations แรก
        fullText = textAnnotations[0]['description'] as String? ?? '';
      }
      
      // แยกข้อความเป็นบรรทัด
      final lines = fullText.split('\n').map((line) => line.trim()).toList();
      final cleanLines = lines.where((line) => line.isNotEmpty).toList();

      // วิเคราะห์ข้อมูลจากข้อความ
      return _analyzeReceiptText(cleanLines, fullText);
    } catch (e) {
      throw Exception('Failed to parse receipt data: $e');
    }
  }

  /// วิเคราะห์ข้อมูลจากข้อความที่สแกนได้
  ReceiptOCRResult _analyzeReceiptText(List<String> lines, String fullText) {
    final analyzer = ReceiptTextAnalyzer();
    final analysis = analyzer.analyzeReceiptWithCategory(lines);
    
    // เพิ่ม fullText ลงในผลการวิเคราะห์
    analysis['rawText'] = fullText;
    
    return ReceiptOCRResult.fromAnalysis(analysis);
  }

  /// สร้างข้อมูลสำหรับกรอกฟอร์มอัตโนมัติ
  Map<String, dynamic> _generateFormData(Map<String, dynamic> analysis) {
    final formData = <String, dynamic>{
      'basicInfo': {
        'storeName': analysis['storeName'] ?? '',
        'amount': analysis['amount'],
        'date': analysis['date']?.toIso8601String(),
        'description': analysis['description'] ?? '',
      },
      'metadata': {
        'confidence': analysis['confidence'] ?? 0.0,
        'hasCategory': analysis['category'] != null,
        'textLength': (analysis['rawText'] as String?)?.length ?? 0,
      }
    };

    // เพิ่มข้อมูลตามประเภท
    final categoryId = analysis['category'];
    if (categoryId != null) {
      try {
        final category = ReceiptCategory.values.firstWhere((c) => c.id == categoryId);
        formData['category'] = {
          'id': category.id,
          'name': category.displayName,
          'formConfig': category.getDefaultFormData(),
        };

        // เพิ่มข้อมูลเฉพาะประเภท
        final categoryData = analysis['categorySpecificData'];
        if (categoryData != null && categoryData.isNotEmpty) {
          formData['categorySpecific'] = _formatCategoryDataForForm(category, categoryData);
        }
      } catch (e) {
        // หากไม่พบประเภทให้ใช้ข้อมูลพื้นฐาน
        formData['category'] = null;
        formData['categoryError'] = 'Unknown category: $categoryId';
      }
    }

    // เพิ่มคำแนะนำสำหรับการกรอกฟอร์ม
    formData['formHints'] = _generateFormHints(analysis);
    
    // เพิ่มข้อมูลการตรวจสอบ
    formData['validation'] = _generateValidationInfo(analysis);

    return formData;
  }

  /// จัดรูปแบบข้อมูลเฉพาะประเภทสำหรับฟอร์ม
  Map<String, dynamic> _formatCategoryDataForForm(ReceiptCategory category, Map<String, dynamic> data) {
    final formattedData = <String, dynamic>{};
    
    switch (category) {
      case ReceiptCategory.water:
        formattedData.addAll({
          'unitsUsed': _formatNumber(data['unitsUsed']),
          'previousReading': _formatNumber(data['previousReading']),
          'currentReading': _formatNumber(data['currentReading']),
          'customerNumber': _formatString(data['customerNumber']),
          'utilityType': 'water',
          'displayData': {
            'usage': data['unitsUsed'] != null ? '${data['unitsUsed']} หน่วย' : null,
            'meterRange': _formatMeterRange(data['previousReading'], data['currentReading']),
          }
        });
        break;

      case ReceiptCategory.electricity:
        formattedData.addAll({
          'kwhUsed': _formatNumber(data['kwhUsed']),
          'previousReading': _formatNumber(data['previousReading']),
          'currentReading': _formatNumber(data['currentReading']),
          'customerNumber': _formatString(data['customerNumber']),
          'utilityType': 'electricity',
          'displayData': {
            'usage': data['kwhUsed'] != null ? '${data['kwhUsed']} kWh' : null,
            'meterRange': _formatMeterRange(data['previousReading'], data['currentReading']),
          }
        });
        break;

      case ReceiptCategory.fuel:
        formattedData.addAll({
          'fuelType': _formatString(data['fuelType']) ?? 'ไม่ระบุ',
          'liters': _formatNumber(data['liters']),
          'pricePerLiter': _formatNumber(data['pricePerLiter']),
          'pumpNumber': _formatNumber(data['pumpNumber']),
          'displayData': {
            'fuelInfo': _formatFuelInfo(data),
            'costBredown': _formatCostBreakdown(data),
          }
        });
        break;

      case ReceiptCategory.supermarket:
      case ReceiptCategory.convenience:
        final items = data['items'] as List<dynamic>? ?? [];
        formattedData.addAll({
          'items': items.map((item) => _formatShoppingItem(item)).toList(),
          'itemCount': items.length,
          'memberNumber': _formatString(data['memberNumber']),
          'totalDiscount': _formatNumber(data['totalDiscount']),
          'pointsEarned': _formatNumber(data['pointsEarned']),
          'displayData': {
            'summary': '${items.length} รายการ',
            'topItems': items.take(3).map((item) => item['name']).join(', '),
          }
        });
        break;
    }
    
    return formattedData;
  }

  /// สร้างคำแนะนำสำหรับการกรอกฟอร์ม
  List<String> _generateFormHints(Map<String, dynamic> analysis) {
    final hints = <String>[];
    final confidence = analysis['confidence'] as double? ?? 0.0;
    
    if (confidence < 0.5) {
      hints.add('ความแม่นยำในการสแกนต่ำ กรุณาตรวจสอบข้อมูลให้ถี่ถ้วน');
    }
    
    if (analysis['storeName'] == null || (analysis['storeName'] as String).isEmpty) {
      hints.add('ไม่พบชื่อร้านค้า กรุณากรอกชื่อร้านให้ชัดเจน');
    }
    
    if (analysis['amount'] == null) {
      hints.add('ไม่พบจำนวนเงิน กรุณาตรวจสอบและกรอกจำนวนเงินให้ถูกต้อง');
    }
    
    if (analysis['date'] == null) {
      hints.add('ไม่พบวันที่ กรุณาเลือกวันที่ทำรายการ');
    }
    
    final categoryId = analysis['category'];
    if (categoryId != null) {
      final category = ReceiptCategory.values.firstWhere((c) => c.id == categoryId);
      hints.add('ตรวจพบใบเสร็จประเภท: ${category.displayName}');
      
      // เพิ่มคำแนะนำเฉพาะประเภท
      hints.addAll(_getCategorySpecificHints(category, analysis));
    } else {
      hints.add('ไม่สามารถระบุประเภทใบเสร็จได้ กรุณาเลือกประเภทที่เหมาะสม');
    }
    
    return hints;
  }

  /// สร้างคำแนะนำเฉพาะประเภท
  List<String> _getCategorySpecificHints(ReceiptCategory category, Map<String, dynamic> analysis) {
    final hints = <String>[];
    final categoryData = analysis['categorySpecificData'] as Map<String, dynamic>?;
    
    if (categoryData == null) {
      hints.add('ไม่พบข้อมูลเฉพาะประเภท ${category.displayName}');
      return hints;
    }
    
    switch (category) {
      case ReceiptCategory.water:
      case ReceiptCategory.electricity:
        if (categoryData['customerNumber'] != null) {
          hints.add('พบเลขที่ผู้ใช้: ${categoryData['customerNumber']}');
        }
        if (categoryData['unitsUsed'] != null || categoryData['kwhUsed'] != null) {
          final units = categoryData['unitsUsed'] ?? categoryData['kwhUsed'];
          hints.add('การใช้งาน: $units ${category == ReceiptCategory.water ? 'หน่วย' : 'kWh'}');
        }
        break;
        
      case ReceiptCategory.fuel:
        if (categoryData['fuelType'] != null) {
          hints.add('ประเภทน้ำมัน: ${categoryData['fuelType']}');
        }
        if (categoryData['liters'] != null) {
          hints.add('ปริมาณ: ${categoryData['liters']} ลิตร');
        }
        break;
        
      case ReceiptCategory.supermarket:
      case ReceiptCategory.convenience:
        final items = categoryData['items'] as List?;
        if (items != null && items.isNotEmpty) {
          hints.add('พบ ${items.length} รายการสินค้า');
        }
        break;
    }
    
    return hints;
  }

  /// สร้างคำแนะนำการใช้งาน
  Map<String, dynamic> _generateUsageSuggestions(Map<String, dynamic> analysis) {
    final suggestions = <String, dynamic>{
      'dataQuality': _assessDataQuality(analysis),
      'improvementTips': _getImprovementTips(analysis),
      'nextSteps': _getNextSteps(analysis),
    };
    
    return suggestions;
  }

  /// ประเมินคุณภาพข้อมูล
  Map<String, dynamic> _assessDataQuality(Map<String, dynamic> analysis) {
    final confidence = analysis['confidence'] as double? ?? 0.0;
    final hasAmount = analysis['amount'] != null;
    final hasDate = analysis['date'] != null;
    final hasStoreName = analysis['storeName'] != null && (analysis['storeName'] as String).isNotEmpty;
    final hasCategory = analysis['category'] != null;
    
    int score = 0;
    if (confidence > 0.7) score += 25;
    else if (confidence > 0.5) score += 15;
    else if (confidence > 0.3) score += 10;
    
    if (hasAmount) score += 25;
    if (hasDate) score += 20;
    if (hasStoreName) score += 15;
    if (hasCategory) score += 15;
    
    String quality;
    String description;
    
    if (score >= 80) {
      quality = 'excellent';
      description = 'ข้อมูลมีคุณภาพดีมาก พร้อมใช้งาน';
    } else if (score >= 60) {
      quality = 'good';
      description = 'ข้อมูลมีคุณภาพดี อาจต้องตรวจสอบเล็กน้อย';
    } else if (score >= 40) {
      quality = 'fair';
      description = 'ข้อมูลมีคุณภาพปานกลาง ควรตรวจสอบก่อนใช้งาน';
    } else {
      quality = 'poor';
      description = 'ข้อมูลมีคุณภาพต่ำ ต้องปรับแต่งก่อนใช้งาน';
    }
    
    return {
      'score': score,
      'quality': quality,
      'description': description,
      'details': {
        'hasAmount': hasAmount,
        'hasDate': hasDate,
        'hasStoreName': hasStoreName,
        'hasCategory': hasCategory,
        'confidence': confidence,
      }
    };
  }

  /// รับคำแนะนำในการปรับปรุง
  List<String> _getImprovementTips(Map<String, dynamic> analysis) {
    final tips = <String>[];
    final confidence = analysis['confidence'] as double? ?? 0.0;
    
    if (confidence < 0.5) {
      tips.addAll([
        'ลองถ่ายภาพในแสงที่สว่างขึ้น',
        'ตรวจสอบว่าใบเสร็จไม่เบลอหรือชำรุด',
        'ถ่ายภาพให้ใบเสร็จอยู่ตรงกลางและเต็มเฟรม',
      ]);
    }
    
    if (analysis['amount'] == null) {
      tips.add('หากไม่พบจำนวนเงิน ให้มองหาคำว่า "รวม", "Total", "ยอดรวม" ในใบเสร็จ');
    }
    
    if (analysis['date'] == null) {
      tips.add('หากไม่พบวันที่ ให้มองหาวันที่ในรูปแบบ วว/ดด/ปป หรือ Date ในใบเสร็จ');
    }
    
    return tips;
  }

  /// รับขั้นตอนถัดไป
  List<String> _getNextSteps(Map<String, dynamic> analysis) {
    final steps = <String>[];
    final hasCategory = analysis['category'] != null;
    
    steps.add('ตรวจสอบและแก้ไขข้อมูลที่ไม่ถูกต้อง');
    
    if (hasCategory) {
      steps.add('กรอกข้อมูลเพิ่มเติมตามประเภทใบเสร็จ');
    } else {
      steps.add('เลือกประเภทใบเสร็จที่เหมาะสม');
    }
    
    steps.addAll([
      'เลือกหมวดหมู่การใช้จ่าย',
      'บันทึกข้อมูลลงในระบบ',
    ]);
    
    return steps;
  }

  /// สร้างข้อมูลการตรวจสอบ
  Map<String, dynamic> _generateValidationInfo(Map<String, dynamic> analysis) {
    final validation = <String, dynamic>{
      'warnings': <String>[],
      'errors': <String>[],
      'checks': <String, bool>{},
    };
    
    // ตรวจสอบข้อมูลพื้นฐาน
    final amount = analysis['amount'] as double?;
    final date = analysis['date'] as DateTime?;
    final storeName = analysis['storeName'] as String?;
    
    validation['checks']['hasAmount'] = amount != null;
    validation['checks']['hasDate'] = date != null;
    validation['checks']['hasStoreName'] = storeName != null && storeName.isNotEmpty;
    validation['checks']['hasValidAmount'] = amount != null && amount > 0;
    validation['checks']['hasValidDate'] = date != null && date.isBefore(DateTime.now().add(Duration(days: 1)));
    
    // เพิ่ม warnings
    if (amount == null) {
      validation['warnings'].add('ไม่พบจำนวนเงิน');
    } else if (amount <= 0) {
      validation['errors'].add('จำนวนเงินไม่ถูกต้อง');
    }
    
    if (date == null) {
      validation['warnings'].add('ไม่พบวันที่');
    } else if (date.isAfter(DateTime.now())) {
      validation['warnings'].add('วันที่เป็นอนาคต');
    }
    
    if (storeName == null || storeName.isEmpty) {
      validation['warnings'].add('ไม่พบชื่อร้านค้า');
    }
    
    return validation;
  }

  /// จำแนกประเภท error
  String _categorizeError(String error) {
    final lowerError = error.toLowerCase();
    
    if (lowerError.contains('network') || lowerError.contains('connection')) {
      return 'network_error';
    } else if (lowerError.contains('timeout')) {
      return 'timeout_error';
    } else if (lowerError.contains('api') || lowerError.contains('quota')) {
      return 'api_error';
    } else if (lowerError.contains('image') || lowerError.contains('file')) {
      return 'image_error';
    } else if (lowerError.contains('parse') || lowerError.contains('format')) {
      return 'data_error';
    } else {
      return 'unknown_error';
    }
  }

  // === Helper Methods for Data Formatting ===

  String? _formatString(dynamic value) {
    if (value == null) return null;
    return value.toString().trim();
  }

  double? _formatNumber(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  String? _formatMeterRange(dynamic previous, dynamic current) {
    final prev = _formatNumber(previous);
    final curr = _formatNumber(current);
    
    if (prev != null && curr != null) {
      return '$prev → $curr';
    }
    return null;
  }

  String _formatFuelInfo(Map<String, dynamic> data) {
    final parts = <String>[];
    
    if (data['fuelType'] != null) {
      parts.add(data['fuelType'].toString());
    }
    if (data['liters'] != null) {
      parts.add('${data['liters']} L');
    }
    
    return parts.join(' ');
  }

  String? _formatCostBreakdown(Map<String, dynamic> data) {
    final liters = _formatNumber(data['liters']);
    final pricePerLiter = _formatNumber(data['pricePerLiter']);
    
    if (liters != null && pricePerLiter != null) {
      return '${liters}L × ${pricePerLiter}฿/L';
    }
    return null;
  }

  Map<String, dynamic> _formatShoppingItem(dynamic item) {
    if (item is Map<String, dynamic>) {
      return {
        'name': _formatString(item['name']) ?? 'Unknown Item',
        'price': _formatNumber(item['price']) ?? 0.0,
        'quantity': _formatNumber(item['quantity']) ?? 1.0,
        'total': _formatNumber(item['total']) ?? (_formatNumber(item['price']) ?? 0.0) * (_formatNumber(item['quantity']) ?? 1.0),
        'discount': _formatNumber(item['discount']),
        'category': _formatString(item['category']),
      };
    } else if (item is String) {
      // หากเป็น string อย่างเดียว ให้ใช้เป็นชื่อสินค้า
      return {
        'name': item.trim(),
        'price': 0.0,
        'quantity': 1.0,
        'total': 0.0,
        'discount': null,
        'category': null,
      };
    }
    
    // Default fallback
    return {
      'name': 'Unknown Item',
      'price': 0.0,
      'quantity': 1.0,
      'total': 0.0,
      'discount': null,
      'category': null,
    };
  }

  /// ฟังก์ชันยูทิลิตี้เพิ่มเติม

  /// ตรวจสอบคุณภาพของข้อความที่สแกนได้
  Map<String, dynamic> analyzeTextQuality(String rawText) {
    final lines = rawText.split('\n').where((line) => line.trim().isNotEmpty).toList();
    final totalChars = rawText.length;
    final alphaNumericChars = rawText.replaceAll(RegExp(r'[^a-zA-Z0-9ก-๙]'), '').length;
    final specialChars = totalChars - alphaNumericChars - rawText.replaceAll(RegExp(r'\s'), '').length;
    
    // คำนวณอัตราส่วนต่างๆ
    final alphaNumericRatio = totalChars > 0 ? alphaNumericChars / totalChars : 0.0;
    final specialCharRatio = totalChars > 0 ? specialChars / totalChars : 0.0;
    final avgLineLength = lines.isNotEmpty ? totalChars / lines.length : 0.0;
    
    // ประเมินคุณภาพ
    String quality = 'unknown';
    List<String> issues = [];
    
    if (totalChars < 20) {
      quality = 'poor';
      issues.add('ข้อความสั้นเกินไป');
    } else if (alphaNumericRatio < 0.3) {
      quality = 'poor';
      issues.add('มีอักขระพิเศษมากเกินไป อาจเป็นเพราะการสแกนไม่ชัดเจน');
    } else if (lines.length < 3) {
      quality = 'fair';
      issues.add('จำนวนบรรทัดน้อย อาจไม่ใช่ใบเสร็จปกติ');
    } else if (avgLineLength > 100) {
      quality = 'fair';
      issues.add('บรรทัดยาวเกินไป อาจมีการแยกบรรทัดไม่ถูกต้อง');
    } else {
      quality = 'good';
    }
    
    return {
      'quality': quality,
      'issues': issues,
      'statistics': {
        'totalChars': totalChars,
        'totalLines': lines.length,
        'avgLineLength': avgLineLength.round(),
        'alphaNumericRatio': (alphaNumericRatio * 100).round(),
        'specialCharRatio': (specialCharRatio * 100).round(),
      },
      'recommendations': _getTextQualityRecommendations(quality, issues),
    };
  }

  /// รับคำแนะนำสำหรับปรับปรุงคุณภาพการสแกน
  List<String> _getTextQualityRecommendations(String quality, List<String> issues) {
    final recommendations = <String>[];
    
    if (quality == 'poor') {
      recommendations.addAll([
        'ลองถ่ายภาพใหม่ในแสงที่ดีขึ้น',
        'ตรวจสอบว่าใบเสร็จไม่เบลอหรือมีรอยพับ',
        'วางใบเสร็จบนพื้นผิวเรียบและถ่ายจากด้านบน',
      ]);
    } else if (quality == 'fair') {
      recommendations.addAll([
        'ตรวจสอบการจัดวางใบเสร็จให้อยู่ตรงกลางภาพ',
        'ลองปรับระยะห่างของกล้องให้เหมาะสม',
      ]);
    } else {
      recommendations.add('คุณภาพการสแกนดี สามารถใช้งานได้');
    }
    
    return recommendations;
  }

  /// สร้างข้อมูลสรุปสำหรับแสดงผล
  Map<String, dynamic> generateDisplaySummary(Map<String, dynamic> analysis) {
    final summary = <String, dynamic>{
      'title': _generateReceiptTitle(analysis),
      'subtitle': _generateReceiptSubtitle(analysis),
      'mainInfo': _generateMainDisplayInfo(analysis),
      'additionalInfo': _generateAdditionalDisplayInfo(analysis),
      'statusInfo': _generateStatusInfo(analysis),
    };
    
    return summary;
  }

  String _generateReceiptTitle(Map<String, dynamic> analysis) {
    final storeName = analysis['storeName'] as String?;
    final categoryId = analysis['category'] as String?;
    
    if (storeName != null && storeName.isNotEmpty) {
      return storeName;
    } else if (categoryId != null) {
      try {
        final category = ReceiptCategory.values.firstWhere((c) => c.id == categoryId);
        return 'ใบเสร็จ${category.displayName}';
      } catch (e) {
        return 'ใบเสร็จ';
      }
    }
    
    return 'ใบเสร็จ';
  }

  String _generateReceiptSubtitle(Map<String, dynamic> analysis) {
    final parts = <String>[];
    
    final date = analysis['date'] as DateTime?;
    if (date != null) {
      final formatter = DateFormat('d MMM yyyy', 'th');
      parts.add(formatter.format(date));
    }
    
    final amount = analysis['amount'] as double?;
    if (amount != null) {
      parts.add('${amount.toStringAsFixed(2)} ฿');
    }
    
    return parts.isNotEmpty ? parts.join(' • ') : 'ไม่มีข้อมูลเพิ่มเติม';
  }

  List<Map<String, String>> _generateMainDisplayInfo(Map<String, dynamic> analysis) {
    final info = <Map<String, String>>[];
    
    // ข้อมูลพื้นฐาน
    final amount = analysis['amount'] as double?;
    if (amount != null) {
      info.add({
        'label': 'จำนวนเงิน',
        'value': '${amount.toStringAsFixed(2)} ฿',
        'icon': 'money',
      });
    }
    
    final date = analysis['date'] as DateTime?;
    if (date != null) {
      final formatter = DateFormat('d MMMM yyyy เวลา HH:mm', 'th');
      info.add({
        'label': 'วันที่',
        'value': formatter.format(date),
        'icon': 'calendar',
      });
    }
    
    final storeName = analysis['storeName'] as String?;
    if (storeName != null && storeName.isNotEmpty) {
      info.add({
        'label': 'ร้านค้า',
        'value': storeName,
        'icon': 'store',
      });
    }
    
    return info;
  }

  List<Map<String, String>> _generateAdditionalDisplayInfo(Map<String, dynamic> analysis) {
    final info = <Map<String, String>>[];
    final categoryId = analysis['category'] as String?;
    
    if (categoryId != null) {
      try {
        final category = ReceiptCategory.values.firstWhere((c) => c.id == categoryId);
        info.add({
          'label': 'ประเภท',
          'value': category.displayName,
          'icon': 'category',
        });
        
        // เพิ่มข้อมูลเฉพาะประเภท
        final categoryData = analysis['categorySpecificData'] as Map<String, dynamic>?;
        if (categoryData != null) {
          info.addAll(_getCategorySpecificDisplayInfo(category, categoryData));
        }
      } catch (e) {
        // Ignore unknown category
      }
    }
    
    return info;
  }

  List<Map<String, String>> _getCategorySpecificDisplayInfo(ReceiptCategory category, Map<String, dynamic> data) {
    final info = <Map<String, String>>[];
    
    switch (category) {
      case ReceiptCategory.water:
      case ReceiptCategory.electricity:
        final customerNumber = data['customerNumber'] as String?;
        if (customerNumber != null) {
          info.add({
            'label': 'เลขที่ผู้ใช้',
            'value': customerNumber,
            'icon': 'account',
          });
        }
        
        final units = data['unitsUsed'] ?? data['kwhUsed'];
        if (units != null) {
          info.add({
            'label': 'การใช้งาน',
            'value': '$units ${category == ReceiptCategory.water ? 'หน่วย' : 'kWh'}',
            'icon': 'meter',
          });
        }
        break;
        
      case ReceiptCategory.fuel:
        final fuelType = data['fuelType'] as String?;
        final liters = data['liters'] as double?;
        
        if (fuelType != null || liters != null) {
          String value = '';
          if (fuelType != null) value += fuelType;
          if (liters != null) {
            if (value.isNotEmpty) value += ' ';
            value += '${liters} L';
          }
          
          info.add({
            'label': 'น้ำมัน',
            'value': value,
            'icon': 'fuel',
          });
        }
        break;
        
      case ReceiptCategory.supermarket:
      case ReceiptCategory.convenience:
        final items = data['items'] as List?;
        if (items != null && items.isNotEmpty) {
          info.add({
            'label': 'รายการสินค้า',
            'value': '${items.length} รายการ',
            'icon': 'shopping',
          });
        }
        break;
    }
    
    return info;
  }

  Map<String, dynamic> _generateStatusInfo(Map<String, dynamic> analysis) {
    final confidence = analysis['confidence'] as double? ?? 0.0;
    final hasCategory = analysis['category'] != null;
    final hasAmount = analysis['amount'] != null;
    final hasDate = analysis['date'] != null;
    
    String status;
    String statusColor;
    String statusMessage;
    
    if (confidence > 0.8 && hasCategory && hasAmount && hasDate) {
      status = 'excellent';
      statusColor = 'green';
      statusMessage = 'ข้อมูลครบถ้วนและมีคุณภาพดีมาก';
    } else if (confidence > 0.6 && hasAmount) {
      status = 'good';
      statusColor = 'blue';
      statusMessage = 'ข้อมูลมีคุณภาพดี อาจต้องตรวจสอบเล็กน้อย';
    } else if (hasAmount || hasDate) {
      status = 'fair';
      statusColor = 'orange';
      statusMessage = 'ข้อมูลบางส่วนสมบูรณ์ ควรตรวจสอบเพิ่มเติม';
    } else {
      status = 'poor';
      statusColor = 'red';
      statusMessage = 'ข้อมูลไม่สมบูรณ์ ต้องแก้ไขก่อนใช้งาน';
    }
    
    return {
      'status': status,
      'color': statusColor,
      'message': statusMessage,
      'confidence': (confidence * 100).round(),
    };
  }

  /// ฟังก์ชันสำหรับ Export ข้อมูล
  Map<String, dynamic> exportReceiptData(Map<String, dynamic> analysis) {
    return {
      'version': '1.0',
      'exportedAt': DateTime.now().toIso8601String(),
      'data': {
        'basic': {
          'storeName': analysis['storeName'],
          'amount': analysis['amount'],
          'date': analysis['date']?.toIso8601String(),
          'description': analysis['description'],
        },
        'category': analysis['category'],
        'categoryData': analysis['categorySpecificData'],
        'rawText': analysis['rawText'],
        'confidence': analysis['confidence'],
      },
      'metadata': {
        'source': 'GoogleVisionService',
        'processingVersion': '2.0',
      },
    };
  }

  /// ฟังก์ชันสำหรับ Import ข้อมูล
  Map<String, dynamic>? importReceiptData(Map<String, dynamic> exportedData) {
    try {
      if (exportedData['version'] != '1.0') {
        throw Exception('Unsupported data version');
      }
      
      final data = exportedData['data'] as Map<String, dynamic>;
      final basic = data['basic'] as Map<String, dynamic>;
      
      return {
        'storeName': basic['storeName'],
        'amount': basic['amount'],
        'date': basic['date'] != null ? DateTime.parse(basic['date']) : null,
        'description': basic['description'],
        'category': data['category'],
        'categorySpecificData': data['categoryData'],
        'rawText': data['rawText'],
        'confidence': data['confidence'],
        'imported': true,
        'importedAt': DateTime.now(),
      };
    } catch (e) {
      return null;
    }
  }

  /// ฟังก์ชันทดสอบการเชื่อมต่อ API
  Future<bool> testConnection() async {
    try {
      // สร้างรูปภาพทดสอบขนาดเล็ก (1x1 pixel PNG)
      final testImageBase64 = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==';
      
      final requestBody = {
        'requests': [
          {
            'image': {'content': testImageBase64},
            'features': [{'type': 'TEXT_DETECTION', 'maxResults': 1}]
          }
        ]
      };
      
      final response = await _callVisionApi(requestBody);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// รับข้อมูลสถิติการใช้งาน API
  Map<String, dynamic> getUsageStats() {
    // ในการใช้งานจริง อาจต้องเก็บสถิติใน SharedPreferences หรือ Database
    return {
      'totalRequests': 0,
      'successfulRequests': 0,
      'failedRequests': 0,
      'lastUsed': null,
      'averageProcessingTime': 0.0,
    };
  }
}