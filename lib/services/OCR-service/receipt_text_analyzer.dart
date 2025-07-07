// services/receipt_text_analyzer.dart
import 'package:intl/intl.dart';

enum ReceiptCategory {
  electricity('ค่าไฟ'),
  water('ค่าน้ำ'),
  fuel('ค่าน้ำมัน'),
  convenience('ร้านสะดวกซื้อ'),
  supermarket('ซุปเปอร์มาเก็ต'),
  other('อื่นๆ');

  const ReceiptCategory(this.displayName);
  final String displayName;
}

class ReceiptTextAnalyzer {
  // รูปแบบวันที่ที่เป็นไปได้
  static final List<DateFormat> _dateFormats = [
    DateFormat('dd/MM/yyyy'),
    DateFormat('dd-MM-yyyy'),
    DateFormat('dd.MM.yyyy'),
    DateFormat('d/M/yyyy'),
    DateFormat('d-M-yyyy'),
    DateFormat('d.M.yyyy'),
    DateFormat('dd/MM/yy'),
    DateFormat('dd-MM-yy'),
    DateFormat('d/M/yy'),
    DateFormat('d-M-yy'),
    DateFormat('yyyy-MM-dd'),
    DateFormat('yyyy/MM/dd'),
  ];

  // คำสำคัญสำหรับจำนวนเงิน
  static final List<String> _amountKeywords = [
    'total', 'รวม', 'ยอดรวม', 'sum', 'amount', 'จำนวน', 'เป็นเงิน',
    'grand total', 'subtotal', 'net', 'รวมทั้งสิ้น', 'ทั้งหมด'
  ];

  // คำสำคัญสำหรับชื่อร้าน
  static final List<String> _storeKeywords = [
    'company', 'co.', 'ltd', 'limited', 'corp', 'inc', 'shop', 'store',
    'ร้าน', 'บริษัท', 'จำกัด', 'ห้างหุ้นส่วน', 'มหาชน'
  ];

  // คำสำคัญสำหรับวันที่
  static final List<String> _dateKeywords = [
    'date', 'วันที่', 'เมื่อ', 'time', 'เวลา', 'transaction', 'receipt'
  ];

  // คำสำคัญสำหรับหมวดหมู่ต่างๆ
  static final Map<ReceiptCategory, List<String>> _categoryKeywords = {
    ReceiptCategory.electricity: [
      'การไฟฟ้า', 'ค่าไฟฟ้า', 'ค่าไฟ', 'electric', 'electricity', 'pea', 'mea',
      'provincial electricity', 'metropolitan electricity', 'กฟภ', 'กฟน',
      'electric bill', 'power bill', 'utility bill', 'kWh', 'กิโลวัตต์',
      'มิเตอร์ไฟฟ้า', 'หน่วยไฟฟ้า', 'อัตราค่าไฟฟ้า'
    ],
    ReceiptCategory.water: [
      'การประปา', 'ค่าน้ำ', 'ค่าน้ำประปา', 'water', 'waterworks', 'pwa',
      'provincial waterworks', 'metropolitan waterworks', 'กปภ', 'กปน',
      'water bill', 'น้ำประปา', 'มิเตอร์น้ำ', 'หน่วยน้ำ', 'ลูกบาศก์เมตร',
      'water supply', 'water authority', 'อัตราค่าน้ำ'
    ],
    ReceiptCategory.fuel: [
      'ปตท', 'shell', 'esso', 'caltex', 'susco', 'pt', 'bcp', 'bangchak',
      'น้ำมัน', 'เบนซิน', 'ดีเซล', 'แก๊ส', 'lpg', 'ngv', 'gasoline',
      'diesel', 'fuel', 'petrol', 'gas station', 'ปั๊มน้ำมัน',
      'สถานีบริการน้ำมัน', 'fuel station', 'oil company', 'octane',
      'premium', 'regular', 'หัวฉีดน้ำมัน', 'fuel pump'
    ],
    ReceiptCategory.convenience: [
      '7-eleven', 'เซเว่น', 'เซเว่นอีเลเว่น', 'family mart', 'แฟมิลี่มาร์ท',
      'lotus express', 'โลตัส เอ็กซ์เพรส', 'jiffy', 'จิฟฟี่',
      'max value', 'แม็กซ์ แวลู', 'cj more', 'ซีเจมอร์',
      'convenience store', 'ร้านสะดวกซื้อ', 'มินิมาร์ท', 'mini mart',
      'quick shop', 'ร้านสะดวกซื้อ', 'ร้านค้า 24 ชม.', '24 hours'
    ],
    ReceiptCategory.supermarket: [
      'big c', 'บิ๊กซี', 'lotus', 'โลตัส', 'tesco', 'เทสโก้',
      'central', 'เซ็นทรัล', 'robinson', 'โรบินสัน', 'tops', 'ท็อปส์',
      'makro', 'แมคโคร', 'gourmet', 'กูร์เมต์', 'villa', 'วิลล่า',
      'foodland', 'ฟู้ดแลนด์', 'supermarket', 'ซุปเปอร์มาร์เก็ต',
      'hypermarket', 'ไฮเปอร์มาร์เก็ต', 'department store', 'ห้างสรรพสินค้า',
      'shopping mall', 'ศูนย์การค้า', 'mall', 'มอลล์'
    ],
  };

  /// ดึงชื่อร้านค้าจากข้อความ
  String extractStoreName(List<String> lines) {
    if (lines.isEmpty) return '';

    // ลองหาชื่อร้านจากบรรทัดแรกๆ (มักจะเป็นชื่อร้าน)
    for (int i = 0; i < Math.min(5, lines.length); i++) {
      final line = lines[i];
      
      // ตรวจสอบว่ามีคำสำคัญของร้านค้าหรือไม่
      if (_containsStoreKeywords(line)) {
        return _cleanStoreName(line);
      }
      
      // หากเป็นบรรทัดแรกและมีความยาวเหมาะสม
      if (i == 0 && line.length > 3 && line.length < 50) {
        return _cleanStoreName(line);
      }
    }

    // หากไม่พบ ให้ใช้บรรทัดแรกที่ไม่ใช่ตัวเลขล้วน
    for (final line in lines.take(3)) {
      if (!_isNumericOnly(line) && line.length > 3) {
        return _cleanStoreName(line);
      }
    }

    return lines.isNotEmpty ? _cleanStoreName(lines[0]) : '';
  }

  /// ดึงจำนวนเงินจากข้อความ
  double? extractAmount(List<String> lines) {
    final amounts = <double>[];

    for (final line in lines) {
      // ตรวจสอบบรรทัดที่มีคำสำคัญเกี่ยวกับเงิน
      if (_containsAmountKeywords(line)) {
        final amount = _extractNumberFromLine(line);
        if (amount != null && amount > 0) {
          amounts.add(amount);
        }
      }
      
      // ตรวจสอบรูปแบบเงินทั่วไป
      final patterns = [
        RegExp(r'[\d,]+\.?\d*\s*บาท'),
        RegExp(r'฿\s*[\d,]+\.?\d*'),
        RegExp(r'THB\s*[\d,]+\.?\d*'),
        RegExp(r'[\d,]+\.\d{2}$'),
      ];

      for (final pattern in patterns) {
        final matches = pattern.allMatches(line);
        for (final match in matches) {
          final amount = _extractNumberFromLine(match.group(0) ?? '');
          if (amount != null && amount > 0) {
            amounts.add(amount);
          }
        }
      }
    }

    // คืนค่าที่มากที่สุด (มักเป็นยอดรวม)
    if (amounts.isNotEmpty) {
      amounts.sort((a, b) => b.compareTo(a));
      return amounts.first;
    }

    return null;
  }

  /// ดึงวันที่จากข้อความ
  DateTime? extractDate(List<String> lines) {
    for (final line in lines) {
      // ตรวจสอบบรรทัดที่มีคำสำคัญเกี่ยวกับวันที่
      if (_containsDateKeywords(line)) {
        final date = _parseDateFromLine(line);
        if (date != null) return date;
      }
      
      // ลองแปลงวันที่จากทุกบรรทัด
      final date = _parseDateFromLine(line);
      if (date != null) return date;
    }

    return null;
  }

  /// ดึงคำอธิบายจากข้อความ
  String extractDescription(List<String> lines) {
    final descriptions = <String>[];

    for (final line in lines) {
      // ข้ามบรรทัดที่เป็นชื่อร้าน วันที่ หรือจำนวนเงิน
      if (_isStoreName(line) || _isDate(line) || _isAmount(line)) {
        continue;
      }

      // เพิ่มบรรทัดที่ดูเหมือนรายการสินค้า
      if (_looksLikeItem(line)) {
        descriptions.add(line);
      }
    }

    return descriptions.take(3).join(', '); // เอาแค่ 3 รายการแรก
  }

  /// วิเคราะห์หมวดหมู่ของใบเสร็จ
  ReceiptCategory extractCategory(List<String> lines) {
    final allText = lines.join(' ').toLowerCase();
    
    // นับคะแนนแต่ละหมวดหมู่
    final scores = <ReceiptCategory, int>{};
    
    for (final category in ReceiptCategory.values) {
      if (category == ReceiptCategory.other) continue;
      
      final keywords = _categoryKeywords[category] ?? [];
      int score = 0;
      
      for (final keyword in keywords) {
        final keywordLower = keyword.toLowerCase();
        // นับจำนวนครั้งที่พบคำสำคัญ
        final matches = RegExp(RegExp.escape(keywordLower)).allMatches(allText);
        score += matches.length;
        
        // ให้คะแนนเพิ่มถ้าพบในชื่อร้าน
        final storeName = extractStoreName(lines).toLowerCase();
        if (storeName.contains(keywordLower)) {
          score += 3; // ให้คะแนนมากขึ้นสำหรับชื่อร้าน
        }
      }
      
      scores[category] = score;
    }
    
    // หาหมวดหมู่ที่มีคะแนนสูงสุด
    final maxScore = scores.values.isEmpty ? 0 : scores.values.reduce(Math.max);
    
    if (maxScore == 0) {
      return ReceiptCategory.other;
    }
    
    // คืนค่าหมวดหมู่แรกที่มีคะแนนสูงสุด
    return scores.entries
        .where((entry) => entry.value == maxScore)
        .first
        .key;
  }

  /// ได้คะแนนความมั่นใจในการจัดหมวดหมู่
  double getCategoryConfidence(List<String> lines, ReceiptCategory category) {
    if (category == ReceiptCategory.other) return 0.5;
    
    final allText = lines.join(' ').toLowerCase();
    final keywords = _categoryKeywords[category] ?? [];
    
    int matchCount = 0;
    int totalKeywords = keywords.length;
    
    for (final keyword in keywords) {
      if (allText.contains(keyword.toLowerCase())) {
        matchCount++;
      }
    }
    
    // คำนวณความมั่นใจเป็นเปอร์เซ็นต์
    double confidence = matchCount / totalKeywords;
    
    // ปรับความมั่นใจให้เหมาะสม
    if (confidence > 0.8) return 0.95;
    if (confidence > 0.6) return 0.85;
    if (confidence > 0.4) return 0.75;
    if (confidence > 0.2) return 0.65;
    if (confidence > 0.1) return 0.55;
    
    return 0.5;
  }

  /// คำนวณความมั่นใจในการสแกน
  double calculateConfidence(List<String> lines) {
    double confidence = 0.0;
    
    // มีข้อความ
    if (lines.isNotEmpty) confidence += 0.15;
    
    // มีชื่อร้าน
    if (extractStoreName(lines).isNotEmpty) confidence += 0.25;
    
    // มีจำนวนเงิน
    if (extractAmount(lines) != null) confidence += 0.25;
    
    // มีวันที่
    if (extractDate(lines) != null) confidence += 0.15;
    
    // มีหมวดหมู่ที่ชัดเจน
    final category = extractCategory(lines);
    if (category != ReceiptCategory.other) {
      confidence += 0.20;
    }

    return confidence;
  }

  /// ดึงข้อมูลครบถ้วนจากใบเสร็จ
  Map<String, dynamic> analyzeReceipt(List<String> lines) {
    final category = extractCategory(lines);
    
    return {
      'storeName': extractStoreName(lines),
      'amount': extractAmount(lines),
      'date': extractDate(lines),
      'description': extractDescription(lines),
      'category': category,
      'categoryDisplayName': category.displayName,
      'confidence': calculateConfidence(lines),
      'categoryConfidence': getCategoryConfidence(lines, category),
    };
  }

  // === Helper Methods ===

  bool _containsStoreKeywords(String line) {
    final lowerLine = line.toLowerCase();
    return _storeKeywords.any((keyword) => lowerLine.contains(keyword.toLowerCase()));
  }

  bool _containsAmountKeywords(String line) {
    final lowerLine = line.toLowerCase();
    return _amountKeywords.any((keyword) => lowerLine.contains(keyword.toLowerCase()));
  }

  bool _containsDateKeywords(String line) {
    final lowerLine = line.toLowerCase();
    return _dateKeywords.any((keyword) => lowerLine.contains(keyword.toLowerCase()));
  }

  String _cleanStoreName(String name) {
    return name
        .replaceAll(RegExp(r'[^\w\s\u0E00-\u0E7F]'), '') // เก็บแค่ตัวอักษร ตัวเลข และภาษาไทย
        .trim();
  }

  bool _isNumericOnly(String text) {
    return RegExp(r'^\d+$').hasMatch(text.replaceAll(RegExp(r'[\s,.]'), ''));
  }

  double? _extractNumberFromLine(String line) {
    // ลบเครื่องหมายที่ไม่ต้องการ
    final cleanLine = line
        .replaceAll(RegExp(r'[^\d.,]'), '')
        .replaceAll(',', '');

    return double.tryParse(cleanLine);
  }

  DateTime? _parseDateFromLine(String line) {
    // ลองแปลงด้วยรูปแบบต่างๆ
    for (final format in _dateFormats) {
      try {
        // หาตัวเลขที่ดูเหมือนวันที่
        final datePattern = RegExp(r'\d{1,2}[./-]\d{1,2}[./-]\d{2,4}');
        final match = datePattern.firstMatch(line);
        
        if (match != null) {
          final dateStr = match.group(0)!;
          final date = format.parse(dateStr);
          
          // ตรวจสอบว่าวันที่สมเหตุสมผล
          if (date.year >= 2000 && date.year <= DateTime.now().year + 1) {
            return date;
          }
        }
      } catch (e) {
        // ไม่สามารถแปลงได้ ลองรูปแบบถัดไป
        continue;
      }
    }

    return null;
  }

  bool _isStoreName(String line) {
    return _containsStoreKeywords(line) || 
           (line.length > 3 && line.length < 50 && !_isNumericOnly(line));
  }

  bool _isDate(String line) {
    return _parseDateFromLine(line) != null;
  }

  bool _isAmount(String line) {
    return _extractNumberFromLine(line) != null && 
           (line.contains('บาท') || line.contains('฿') || line.contains('THB'));
  }

  bool _looksLikeItem(String line) {
    return line.length > 3 && 
           line.length < 100 && 
           !_isNumericOnly(line) &&
           !line.contains(RegExp(r'[=#*-]{3,}')); // ไม่ใช่เส้นแยก
  }
}

// Math utility class
class Math {
  static T min<T extends num>(T a, T b) => a < b ? a : b;
  static T max<T extends num>(T a, T b) => a > b ? a : b;
}