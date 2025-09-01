// models/receipt_ocr_result.dart (Enhanced Version)
import 'receipt_category_classifier.dart';

class ReceiptOCRResult {
  final String storeName;
  final double? amount;
  final DateTime? date;
  final String description;
  final String rawText;
  final double confidence;
  final ReceiptCategory? category;
  final Map<String, dynamic>? categorySpecificData;

  const ReceiptOCRResult({
    required this.storeName,
    required this.amount,
    required this.date,
    required this.description,
    required this.rawText,
    required this.confidence,
    this.category,
    this.categorySpecificData,
  });

  /// สร้าง empty result
  factory ReceiptOCRResult.empty() {
    return const ReceiptOCRResult(
      storeName: '',
      amount: null,
      date: null,
      description: '',
      rawText: '',
      confidence: 0.0,
      category: null,
      categorySpecificData: null,
    );
  }

  /// สร้างจากผลการวิเคราะห์
  factory ReceiptOCRResult.fromAnalysis(Map<String, dynamic> analysis) {
    ReceiptCategory? category;
    if (analysis['category'] != null) {
      category = ReceiptCategory.values.firstWhere(
        (c) => c.id == analysis['category'],
        orElse: () => ReceiptCategory.values.first,
      );
    }

    return ReceiptOCRResult(
      storeName: analysis['storeName'] ?? '',
      amount: analysis['amount']?.toDouble(),
      date: analysis['date'],
      description: analysis['description'] ?? '',
      rawText: analysis['rawText'] ?? '',
      confidence: analysis['confidence']?.toDouble() ?? 0.0,
      category: category,
      categorySpecificData: analysis['categorySpecificData'],
    );
  }

  /// แปลงเป็น JSON
  Map<String, dynamic> toJson() {
    return {
      'storeName': storeName,
      'amount': amount,
      'date': date?.millisecondsSinceEpoch,
      'description': description,
      'rawText': rawText,
      'confidence': confidence,
      'category': category?.id,
      'categoryName': category?.displayName,
      'categorySpecificData': categorySpecificData,
    };
  }

  /// สร้างจาก JSON
  factory ReceiptOCRResult.fromJson(Map<String, dynamic> json) {
    ReceiptCategory? category;
    if (json['category'] != null) {
      try {
        category = ReceiptCategory.values.firstWhere(
          (c) => c.id == json['category'],
        );
      } catch (e) {
        category = null;
      }
    }

    return ReceiptOCRResult(
      storeName: json['storeName'] ?? '',
      amount: json['amount']?.toDouble(),
      date: json['date'] != null ? DateTime.fromMillisecondsSinceEpoch(json['date']) : null,
      description: json['description'] ?? '',
      rawText: json['rawText'] ?? '',
      confidence: json['confidence']?.toDouble() ?? 0.0,
      category: category,
      categorySpecificData: json['categorySpecificData'],
    );
  }

  /// ตรวจสอบว่าผลลัพธ์ว่างเปล่าหรือไม่
  bool get isEmpty {
    return storeName.isEmpty && 
           amount == null && 
           date == null && 
           description.isEmpty;
  }

  /// ตรวจสอบว่าผลลัพธ์มีข้อมูลหรือไม่
  bool get isNotEmpty => !isEmpty;

  /// ตรวจสอบว่าผลลัพธ์มีความน่าเชื่อถือหรือไม่
  bool get isReliable => confidence >= 0.5;

  /// ตรวจสอบว่ามีการจำแนกประเภทหรือไม่
  bool get hasCategory => category != null;

  /// ดึงชื่อหมวดหมู่
  String get categoryDisplayName => category?.displayName ?? 'ไม่ทราบประเภท';

  /// ดึงข้อมูลเฉพาะประเภทสำหรับการแสดงผล
  String get formattedCategoryData {
    if (categorySpecificData == null || categorySpecificData!.isEmpty) {
      return '';
    }

    final data = categorySpecificData!;
    final parts = <String>[];

    switch (category) {
      case ReceiptCategory.water:
        if (data['unitsUsed'] != null) parts.add('หน่วย: ${data['unitsUsed']}');
        if (data['customerNumber'] != null) parts.add('เลขที่: ${data['customerNumber']}');
        break;

      case ReceiptCategory.electricity:
        if (data['kwhUsed'] != null) parts.add('kWh: ${data['kwhUsed']}');
        if (data['customerNumber'] != null) parts.add('เลขที่: ${data['customerNumber']}');
        break;

      case ReceiptCategory.fuel:
        if (data['fuelType'] != null) parts.add('ประเภท: ${data['fuelType']}');
        if (data['liters'] != null) parts.add('ลิตร: ${data['liters']}');
        if (data['pricePerLiter'] != null) parts.add('ราคา/ลิตร: ${data['pricePerLiter']}');
        break;

      case ReceiptCategory.supermarket:
      case ReceiptCategory.convenience:
        if (data['items'] != null) {
          final items = data['items'] as List;
          parts.add('รายการ: ${items.length} รายการ');
        }
        if (data['memberNumber'] != null) parts.add('สมาชิก: ${data['memberNumber']}');
        break;

      default:
        break;
    }

    return parts.join(' | ');
  }

  /// คัดลอกพร้อมแก้ไขค่า
  ReceiptOCRResult copyWith({
    String? storeName,
    double? amount,
    DateTime? date,
    String? description,
    String? rawText,
    double? confidence,
    ReceiptCategory? category,
    Map<String, dynamic>? categorySpecificData,
  }) {
    return ReceiptOCRResult(
      storeName: storeName ?? this.storeName,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      description: description ?? this.description,
      rawText: rawText ?? this.rawText,
      confidence: confidence ?? this.confidence,
      category: category ?? this.category,
      categorySpecificData: categorySpecificData ?? this.categorySpecificData,
    );
  }

  @override
  String toString() {
    return 'ReceiptOCRResult(storeName: $storeName, amount: $amount, date: $date, category: ${category?.displayName}, confidence: $confidence)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ReceiptOCRResult &&
        other.storeName == storeName &&
        other.amount == amount &&
        other.date == date &&
        other.description == description &&
        other.rawText == rawText &&
        other.confidence == confidence &&
        other.category == category;
  }

  @override
  int get hashCode {
    return Object.hash(
      storeName,
      amount,
      date,
      description,
      rawText,
      confidence,
      category,
    );
  }
}

/// สถานะการสแกน
enum ScanStatus {
  idle,
  scanning,
  success,
  error,
}

/// ผลลัพธ์การสแกนพร้อมสถานะ
class ScanResult {
  final ScanStatus status;
  final ReceiptOCRResult? result;
  final String? errorMessage;

  const ScanResult({
    required this.status,
    this.result,
    this.errorMessage,
  });

  /// สร้าง idle result
  factory ScanResult.idle() {
    return const ScanResult(status: ScanStatus.idle);
  }

  /// สร้าง scanning result
  factory ScanResult.scanning() {
    return const ScanResult(status: ScanStatus.scanning);
  }

  /// สร้าง success result
  factory ScanResult.success(ReceiptOCRResult result) {
    return ScanResult(
      status: ScanStatus.success,
      result: result,
    );
  }

  /// สร้าง error result
  factory ScanResult.error(String message) {
    return ScanResult(
      status: ScanStatus.error,
      errorMessage: message,
    );
  }

  bool get isIdle => status == ScanStatus.idle;
  bool get isScanning => status == ScanStatus.scanning;
  bool get isSuccess => status == ScanStatus.success;
  bool get isError => status == ScanStatus.error;
}

/// Extension สำหรับ ReceiptCategory ในการแปลงข้อมูลสำหรับฟอร์ม
extension ReceiptCategoryFormData on ReceiptCategory {
  /// สร้างข้อมูลเริ่มต้นสำหรับฟอร์มตามประเภท
  Map<String, dynamic> getDefaultFormData() {
    switch (this) {
      case ReceiptCategory.water:
        return {
          'formType': 'utility',
          'utilityType': 'water',
          'showMeterReading': true,
          'showUnitsUsed': true,
          'showCustomerNumber': true,
        };

      case ReceiptCategory.electricity:
        return {
          'formType': 'utility',
          'utilityType': 'electricity',
          'showMeterReading': true,
          'showUnitsUsed': true,
          'showCustomerNumber': true,
        };

      case ReceiptCategory.fuel:
        return {
          'formType': 'fuel',
          'showFuelType': true,
          'showLiters': true,
          'showPricePerLiter': true,
          'showPumpNumber': true,
        };

      case ReceiptCategory.supermarket:
        return {
          'formType': 'shopping',
          'showItems': true,
          'showMemberNumber': true,
          'showDiscount': true,
          'maxItems': 10,
        };

      case ReceiptCategory.convenience:
        return {
          'formType': 'shopping',
          'showItems': true,
          'showMemberNumber': true,
          'showPoints': true,
          'maxItems': 5,
        };
    }
  }
}