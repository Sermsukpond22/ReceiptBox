// services/receipt_category_classifier.dart
enum ReceiptCategory {
  water('ค่าน้ำ', 'water'),
  electricity('ค่าไฟ', 'electricity'), 
  fuel('ค่าน้ำมัน', 'fuel'),
  supermarket('ซุปเปอร์มาเก็ต', 'supermarket'),
  convenience('ร้านสะดวกซื้อ', 'convenience');

  const ReceiptCategory(this.displayName, this.id);
  
  final String displayName;
  final String id;
}

class ReceiptCategoryClassifier {
  // คำสำคัญสำหรับแต่ละหมวดหมู่
  static final Map<ReceiptCategory, List<String>> _categoryKeywords = {
    ReceiptCategory.water: [
      'การประปา', 'ประปา', 'water', 'น้ำประปา', 'ค่าน้ำ', 'water authority',
      'provincial waterworks', 'pwa', 'เมตรน้ำ', 'มาตรวัดน้ำ', 'หน่วยน้ำ',
      'ปริมาตรการใช้น้ำ', 'metropolitan waterworks', 'mwa'
    ],
    
    ReceiptCategory.electricity: [
      'การไฟฟ้า', 'ไฟฟ้า', 'electricity', 'ค่าไฟ', 'egat', 'pea', 'mea',
      'การไฟฟ้าฝ่ายผลิต', 'การไฟฟ้าส่วนภูมิภาค', 'การไฟฟ้านครหลวง',
      'เมตรไฟ', 'มาตรวัดไฟฟ้า', 'หน่วยไฟฟ้า', 'กิโลวัตต์', 'kwh', 'volt'
    ],
    
    ReceiptCategory.fuel: [
      'ปตท', 'ptt', 'shell', 'เชลล์', 'บางจาก', 'bangchak', 'esso', 'เอสโซ่',
      'caltex', 'คาลเท็กซ์', 'susco', 'สุสโก้', 'น้ำมัน', 'เบนซิน', 'diesel',
      'ดีเซล', 'แก๊สโซฮอล์', 'gasohol', 'e20', 'e85', '91', '95', 'premium',
      'น้ำมันเครื่อง', 'หัวจ่าย', 'pump', 'สถานีบริการ', 'ปั๊มน้ำมัน'
    ],
    
    ReceiptCategory.supermarket: [
      'บิ๊กซี', 'big c', 'เทสโก้', 'tesco', 'lotus', 'โลตัส', 'tops', 'ท็อปส์',
      'แม็คโคร', 'makro', 'villa market', 'วิลล่า', 'gourmet', 'เกาะเม็ด',
      'ริมผิง', 'foodland', 'ฟู้ดแลนด์', 'supermarket', 'ซุปเปอร์มาเก็ต',
      'ห้างสรรพสินค้า', 'shopping center'
    ],
    
    ReceiptCategory.convenience: [
      'เซเว่น', '7-eleven', '7-11', 'seven eleven', 'เซเว่นอีเลเว่น',
      'แฟมิลี่มาร์ท', 'family mart', 'familymart', 'ลอว์สัน', 'lawson',
      'มินิมาร์ท', 'mini mart', 'ร้านสะดวกซื้อ', 'convenience store',
      'cj express', 'ซีเจ', 'max value', 'แม็กซ์แวลู', 'jiffy'
    ],
  };

  // รายละเอียดเฉพาะสำหรับแต่ละหมวดหมู่
  static final Map<ReceiptCategory, List<String>> _categorySpecificFields = {
    ReceiptCategory.water: [
      'หน่วยที่ใช้', 'มาตรเก่า', 'มาตรใหม่', 'อัตราค่าน้ำ', 'ค่าบริการ',
      'ค่าน้ำ', 'หน่วย', 'คิวบิกเมตร', 'm³', 'เลขมาตรวัด'
    ],
    
    ReceiptCategory.electricity: [
      'หน่วยที่ใช้', 'เลขมาตรเก่า', 'เลขมาตรใหม่', 'อัตราค่าไฟ', 
      'ค่าไฟฟ้า', 'kwh', 'กิโลวัตต์', 'ft', 'ค่าบริการ', 'เลขมาตรวัด'
    ],
    
    ReceiptCategory.fuel: [
      'ลิตร', 'liter', 'litre', 'บาท/ลิตร', 'ราคา/ลิตร', 'ปริมาณ',
      'ประเภทน้ำมัน', 'เบนซิน', 'ดีเซล', 'แก๊สโซฮอล์', 'หัวจ่าย'
    ],
    
    ReceiptCategory.supermarket: [
      'รายการสินค้า', 'จำนวน', 'ราคา', 'ส่วนลด', 'คูปอง', 'สมาชิก',
      'บาร์โค้ด', 'sku', 'แผนก', 'หมวดสินค้า'
    ],
    
    ReceiptCategory.convenience: [
      'รายการสินค้า', 'จำนวน', 'ราคา', 'โปรโมชั่น', 'ส่วนลด',
      'สะสมแต้ม', 'all member', 'สมาชิก'
    ],
  };

  /// จำแนกประเภทใบเสร็จจากข้อความ
  static ReceiptCategory? classifyReceipt(String text) {
    if (text.isEmpty) return null;
    
    final lowerText = text.toLowerCase();
    final scores = <ReceiptCategory, int>{};
    
    // คำนวณคะแนนสำหรับแต่ละหมวดหมู่
    for (final category in ReceiptCategory.values) {
      int score = 0;
      
      // คะแนนจากคำสำคัญหลัก
      for (final keyword in _categoryKeywords[category] ?? []) {
        if (lowerText.contains(keyword.toLowerCase())) {
          score += 10;
        }
      }
      
      // คะแนนจากรายละเอียดเฉพาะ
      for (final field in _categorySpecificFields[category] ?? []) {
        if (lowerText.contains(field.toLowerCase())) {
          score += 5;
        }
      }
      
      scores[category] = score;
    }
    
    // คืนหมวดหมู่ที่มีคะแนนสูงสุด
    if (scores.values.any((score) => score > 0)) {
      return scores.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;
    }
    
    return null;
  }

  /// ดึงรายละเอียดเฉพาะตามประเภทใบเสร็จ
  static Map<String, dynamic> extractCategorySpecificData(
    ReceiptCategory category, 
    List<String> lines,
    String fullText
  ) {
    switch (category) {
      case ReceiptCategory.water:
        return _extractWaterBillData(lines, fullText);
      case ReceiptCategory.electricity:
        return _extractElectricityBillData(lines, fullText);
      case ReceiptCategory.fuel:
        return _extractFuelReceiptData(lines, fullText);
      case ReceiptCategory.supermarket:
        return _extractSupermarketReceiptData(lines, fullText);
      case ReceiptCategory.convenience:
        return _extractConvenienceStoreData(lines, fullText);
    }
  }

  /// ดึงข้อมูลใบแจ้งหนี้ค่าน้ำ
  static Map<String, dynamic> _extractWaterBillData(List<String> lines, String fullText) {
    final data = <String, dynamic>{};
    
    for (final line in lines) {
      final lowerLine = line.toLowerCase();
      
      // หาหน่วยที่ใช้
      if (lowerLine.contains('หน่วยที่ใช้') || lowerLine.contains('ใช้น้ำ')) {
        final units = _extractNumber(line);
        if (units != null) data['unitsUsed'] = units;
      }
      
      // หาเลขมาตรเก่า/ใหม่
      if (lowerLine.contains('มาตรเก่า') || lowerLine.contains('previous')) {
        final reading = _extractNumber(line);
        if (reading != null) data['previousReading'] = reading;
      }
      
      if (lowerLine.contains('มาตรใหม่') || lowerLine.contains('current')) {
        final reading = _extractNumber(line);
        if (reading != null) data['currentReading'] = reading;
      }
      
      // หาเลขประจำตัวผู้ใช้น้ำ
      if (lowerLine.contains('เลขที่ผู้ใช้') || lowerLine.contains('customer')) {
        final customerNo = _extractCustomerNumber(line);
        if (customerNo != null) data['customerNumber'] = customerNo;
      }
    }
    
    return data;
  }

  /// ดึงข้อมูลใบแจ้งหนี้ค่าไฟ
  static Map<String, dynamic> _extractElectricityBillData(List<String> lines, String fullText) {
    final data = <String, dynamic>{};
    
    for (final line in lines) {
      final lowerLine = line.toLowerCase();
      
      // หาหน่วยไฟฟ้าที่ใช้
      if (lowerLine.contains('หน่วยที่ใช้') || lowerLine.contains('kwh used')) {
        final units = _extractNumber(line);
        if (units != null) data['kwhUsed'] = units;
      }
      
      // หาเลขมาตรไฟฟ้า
      if (lowerLine.contains('เลขมาตรเก่า') || lowerLine.contains('previous reading')) {
        final reading = _extractNumber(line);
        if (reading != null) data['previousReading'] = reading;
      }
      
      if (lowerLine.contains('เลขมาตรใหม่') || lowerLine.contains('current reading')) {
        final reading = _extractNumber(line);
        if (reading != null) data['currentReading'] = reading;
      }
      
      // หาหมายเลขผู้ใช้ไฟฟ้า
      if (lowerLine.contains('เลขที่ผู้ใช้') || lowerLine.contains('customer')) {
        final customerNo = _extractCustomerNumber(line);
        if (customerNo != null) data['customerNumber'] = customerNo;
      }
    }
    
    return data;
  }

  /// ดึงข้อมูลใบเสร็จน้ำมัน
  static Map<String, dynamic> _extractFuelReceiptData(List<String> lines, String fullText) {
    final data = <String, dynamic>{};
    
    for (final line in lines) {
      final lowerLine = line.toLowerCase();
      
      // หาประเภทน้ำมัน
      if (lowerLine.contains('gasohol') || lowerLine.contains('แก๊สโซฮอล์')) {
        data['fuelType'] = 'Gasohol';
      } else if (lowerLine.contains('benzin') || lowerLine.contains('เบนซิน')) {
        data['fuelType'] = 'Benzin';
      } else if (lowerLine.contains('diesel') || lowerLine.contains('ดีเซล')) {
        data['fuelType'] = 'Diesel';
      }
      
      // หาปริมาณลิตร
      if (lowerLine.contains('liter') || lowerLine.contains('ลิตร')) {
        final liters = _extractNumber(line);
        if (liters != null) data['liters'] = liters;
      }
      
      // หาราคาต่อลิตร
      if (lowerLine.contains('บาท/ลิตร') || lowerLine.contains('price/liter')) {
        final pricePerLiter = _extractNumber(line);
        if (pricePerLiter != null) data['pricePerLiter'] = pricePerLiter;
      }
      
      // หาหมายเลขหัวจ่าย
      if (lowerLine.contains('pump') || lowerLine.contains('หัวจ่าย')) {
        final pumpNo = _extractNumber(line);
        if (pumpNo != null) data['pumpNumber'] = pumpNo;
      }
    }
    
    return data;
  }

  /// ดึงข้อมูลใบเสร็จซุปเปอร์มาเก็ต
  static Map<String, dynamic> _extractSupermarketReceiptData(List<String> lines, String fullText) {
    final data = <String, dynamic>{};
    final items = <Map<String, dynamic>>[];
    
    for (final line in lines) {
      final lowerLine = line.toLowerCase();
      
      // หารายการสินค้า (มักจะมีราคาต่อท้ายบรรทัด)
      if (_containsPrice(line) && !_isTotal(line)) {
        final item = _extractItem(line);
        if (item != null) items.add(item);
      }
      
      // หาเลขสมาชิก
      if (lowerLine.contains('member') || lowerLine.contains('สมาชิก')) {
        final memberNo = _extractCustomerNumber(line);
        if (memberNo != null) data['memberNumber'] = memberNo;
      }
      
      // หาส่วนลดรวม
      if (lowerLine.contains('discount') || lowerLine.contains('ส่วนลด')) {
        final discount = _extractNumber(line);
        if (discount != null) data['totalDiscount'] = discount;
      }
    }
    
    if (items.isNotEmpty) data['items'] = items;
    return data;
  }

  /// ดึงข้อมูลใบเสร็จร้านสะดวกซื้อ
  static Map<String, dynamic> _extractConvenienceStoreData(List<String> lines, String fullText) {
    final data = <String, dynamic>{};
    final items = <Map<String, dynamic>>[];
    
    for (final line in lines) {
      final lowerLine = line.toLowerCase();
      
      // หารายการสินค้า
      if (_containsPrice(line) && !_isTotal(line)) {
        final item = _extractItem(line);
        if (item != null) items.add(item);
      }
      
      // หาเลขสมาชิก All Member
      if (lowerLine.contains('all member') || lowerLine.contains('สมาชิก')) {
        final memberNo = _extractCustomerNumber(line);
        if (memberNo != null) data['memberNumber'] = memberNo;
      }
      
      // หาแต้มที่ได้รับ
      if (lowerLine.contains('point') || lowerLine.contains('แต้ม')) {
        final points = _extractNumber(line);
        if (points != null) data['pointsEarned'] = points;
      }
    }
    
    if (items.isNotEmpty) data['items'] = items;
    return data;
  }

  // Helper methods
  static double? _extractNumber(String text) {
    final numberPattern = RegExp(r'[\d,]+\.?\d*');
    final match = numberPattern.firstMatch(text.replaceAll(' ', ''));
    if (match != null) {
      final numberStr = match.group(0)?.replaceAll(',', '');
      return double.tryParse(numberStr ?? '');
    }
    return null;
  }

  static String? _extractCustomerNumber(String text) {
    final patterns = [
      RegExp(r'\d{10,}'), // เลขยาวๆ
      RegExp(r'\d{4}-\d{4}-\d{4}'), // รูปแบบ xxxx-xxxx-xxxx
    ];
    
    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) return match.group(0);
    }
    return null;
  }

  static Map<String, dynamic>? _extractItem(String line) {
    final parts = line.split(' ');
    if (parts.length < 2) return null;
    
    final priceStr = parts.last.replaceAll(',', '');
    final price = double.tryParse(priceStr);
    
    if (price != null) {
      final itemName = parts.sublist(0, parts.length - 1).join(' ');
      return {
        'name': itemName.trim(),
        'price': price,
        'quantity': 1, // Default quantity
      };
    }
    return null;
  }

  static bool _containsPrice(String line) {
    return RegExp(r'\d+\.?\d*$').hasMatch(line.trim());
  }

  static bool _isTotal(String line) {
    final lowerLine = line.toLowerCase();
    return lowerLine.contains('total') || 
           lowerLine.contains('รวม') || 
           lowerLine.contains('ยอดรวม') ||
           lowerLine.contains('sum');
  }
}