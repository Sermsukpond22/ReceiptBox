// models/receipt_ocr_result.dart
class ReceiptOCRResult {
  final String storeName;
  final double? amount;
  final DateTime? date;
  final String description;
  final String rawText;
  final double confidence;

  const ReceiptOCRResult({
    required this.storeName,
    required this.amount,
    required this.date,
    required this.description,
    required this.rawText,
    required this.confidence,
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
    };
  }

  /// สร้างจาก JSON
  factory ReceiptOCRResult.fromJson(Map<String, dynamic> json) {
    return ReceiptOCRResult(
      storeName: json['storeName'] ?? '',
      amount: json['amount']?.toDouble(),
      date: json['date'] != null ? DateTime.fromMillisecondsSinceEpoch(json['date']) : null,
      description: json['description'] ?? '',
      rawText: json['rawText'] ?? '',
      confidence: json['confidence']?.toDouble() ?? 0.0,
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

  /// คัดลอกพร้อมแก้ไขค่า
  ReceiptOCRResult copyWith({
    String? storeName,
    double? amount,
    DateTime? date,
    String? description,
    String? rawText,
    double? confidence,
  }) {
    return ReceiptOCRResult(
      storeName: storeName ?? this.storeName,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      description: description ?? this.description,
      rawText: rawText ?? this.rawText,
      confidence: confidence ?? this.confidence,
    );
  }

  @override
  String toString() {
    return 'ReceiptOCRResult(storeName: $storeName, amount: $amount, date: $date, confidence: $confidence)';
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
        other.confidence == confidence;
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