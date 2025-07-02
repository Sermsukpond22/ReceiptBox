// add_receipt_page.dart (Complete Version with OCR Scanner)
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:run_android/Screen/Pages/ReceiptPage.dart/Widgets/receipt_scanner_widget.dart';
import 'package:run_android/services/models/receipt_ocr_result.dart';
import 'package:run_android/services/receipt_service.dart';
import 'package:run_android/services/receipt_service.dart' show ReceiptData;


class AddReceiptPage extends StatefulWidget {
  const AddReceiptPage({super.key});

  @override
  State<AddReceiptPage> createState() => _AddReceiptPageState();
}

class _AddReceiptPageState extends State<AddReceiptPage> {
  // State variables
  bool _isProcessing = false;
  bool _isScanning = false;
  File? _imageFile;

  // Controllers
  late final TextEditingController _storeController;
  late final TextEditingController _dateController;
  late final TextEditingController _amountController;
  late final TextEditingController _descriptionController;

  // Services
  late final ReceiptService _receiptService;
  late final ImagePicker _picker;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _initializeServices();
  }

  void _initializeControllers() {
    _storeController = TextEditingController();
    _dateController = TextEditingController();
    _amountController = TextEditingController();
    _descriptionController = TextEditingController();
  }

  void _initializeServices() {
    _receiptService = ReceiptService();
    _picker = ImagePicker();
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  void _disposeControllers() {
    _storeController.dispose();
    _dateController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
  }

  // === OCR HANDLING METHODS ===
  
  void _onScanStart() {
    setState(() {
      _isScanning = true;
    });
    _showInfoSnackBar("กำลังสแกนใบเสร็จ...");
  }

  void _onScanComplete(ReceiptOCRResult result) {
    setState(() {
      _isScanning = false;
    });

    if (result.isNotEmpty) {
      _fillFormFromOCR(result);
      _showScanResultDialog(result);
    } else {
      _showWarningDialog("ไม่พบข้อมูลใบเสร็จ กรุณากรอกข้อมูลด้วยตนเอง");
    }
  }

  void _onScanError(String error) {
    setState(() {
      _isScanning = false;
    });
    _showErrorDialog("เกิดข้อผิดพลาดในการสแกน: $error");
  }

  void _fillFormFromOCR(ReceiptOCRResult result) {
    // กรอกข้อมูลลงในฟอร์ม
    if (result.storeName.isNotEmpty) {
      _storeController.text = result.storeName;
    }
    
    if (result.amount != null) {
      _amountController.text = result.amount!.toStringAsFixed(2);
    }
    
    if (result.date != null) {
      _dateController.text = DateFormat('dd/MM/yyyy').format(result.date!);
    }
    
    if (result.description.isNotEmpty) {
      _descriptionController.text = result.description;
    }
  }

  void _showScanResultDialog(ReceiptOCRResult result) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 28),
              SizedBox(width: 8),
              Text('สแกนสำเร็จ!'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ข้อมูลที่สแกนได้ (ความแม่นยำ: ${(result.confidence * 100).toStringAsFixed(0)}%):'),
              const SizedBox(height: 12),
              if (result.storeName.isNotEmpty) ...[
                Text('• ร้านค้า: ${result.storeName}'),
                const SizedBox(height: 4),
              ],
              if (result.amount != null) ...[
                Text('• จำนวนเงิน: ${result.amount!.toStringAsFixed(2)} บาท'),
                const SizedBox(height: 4),
              ],
              if (result.date != null) ...[
                Text('• วันที่: ${DateFormat('dd/MM/yyyy').format(result.date!)}'),
                const SizedBox(height: 4),
              ],
              if (result.description.isNotEmpty) ...[
                Text('• รายการ: ${result.description}'),
                const SizedBox(height: 4),
              ],
              const SizedBox(height: 12),
              Text(
                'ข้อมูลได้ถูกกรอกลงในฟอร์มแล้ว คุณสามารถแก้ไขได้ตามต้องการ',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('เข้าใจแล้ว'),
            ),
          ],
        );
      },
    );
  }

  // === IMAGE HANDLING METHODS ===
  
  Future<void> _showImageSourceDialog() async {
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildImageSourceBottomSheet(),
    );
  }

  Widget _buildImageSourceBottomSheet() {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildBottomSheetHeader(),
          _buildImageSourceTile(
            icon: Icons.camera_alt,
            title: 'ถ่ายรูป',
            color: Colors.blue,
            onTap: () => _handleImageSource(ImageSource.camera),
          ),
          _buildImageSourceTile(
            icon: Icons.photo_library,
            title: 'เลือกจากคลังภาพ',
            color: Colors.green,
            onTap: () => _handleImageSource(ImageSource.gallery),
          ),
          if (_imageFile != null) _buildRemoveImageTile(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildBottomSheetHeader() {
    return const Padding(
      padding: EdgeInsets.all(16.0),
      child: Text(
        'เลือกรูปภาพใบเสร็จ',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildImageSourceTile({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title),
      onTap: onTap,
    );
  }

  Widget _buildRemoveImageTile() {
    return ListTile(
      leading: const Icon(Icons.delete, color: Colors.red),
      title: const Text('ลบรูปภาพ'),
      onTap: () {
        Navigator.pop(context);
        _removeImage();
      },
    );
  }

  void _handleImageSource(ImageSource source) {
    Navigator.pop(context);
    _pickImage(source);
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
        
        _showSuccessSnackBar("เพิ่มรูปภาพใบเสร็จเรียบร้อยแล้ว");
      }
    } catch (e) {
      _showErrorDialog('เกิดข้อผิดพลาดในการเลือกรูปภาพ: $e');
    }
  }

  void _removeImage() {
    setState(() {
      _imageFile = null;
    });
    _showInfoSnackBar("รูปภาพใบเสร็จถูกลบออกแล้ว");
  }

  // === DATE HANDLING METHODS ===
  
  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    
    if (picked != null) {
      setState(() {
        _dateController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  // === VALIDATION METHODS ===
  
  String? _validateForm() {
    if (!_receiptService.isUserLoggedIn) {
      return 'กรุณาเข้าสู่ระบบก่อนใช้งาน';
    }

    if (_amountController.text.isEmpty || _dateController.text.isEmpty) {
      return 'กรุณากรอกวันที่และจำนวนเงิน';
    }

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      return 'กรุณากรอกจำนวนเงินที่ถูกต้อง';
    }

    try {
      DateFormat('dd/MM/yyyy').parse(_dateController.text);
    } catch (e) {
      return 'กรุณากรอกวันที่ในรูปแบบ วว/ดด/ปปปป';
    }

    return null;
  }

  ReceiptData _createReceiptData() {
    final amount = double.parse(_amountController.text);
    final date = DateFormat('dd/MM/yyyy').parse(_dateController.text);

    return ReceiptData(
      storeName: _storeController.text,
      description: _descriptionController.text,
      amount: amount,
      transactionDate: date,
      imageFile: _imageFile,
    );
  }

  // === SAVE METHODS ===
  
  Future<void> _showSaveConfirmation() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('ยืนยันการบันทึก'),
          content: const Text('คุณต้องการบันทึกข้อมูลใบเสร็จนี้หรือไม่?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('ยกเลิก'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('บันทึก', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _saveReceipt();
    }
  }

  Future<void> _saveReceipt() async {
    // Validate form
    final validationError = _validateForm();
    if (validationError != null) {
      _showWarningDialog(validationError);
      return;
    }

    // Create receipt data
    final receiptData = _createReceiptData();
    
    // Validate receipt data
    final receiptValidationError = ReceiptService.validateReceiptData(receiptData);
    if (receiptValidationError != null) {
      _showWarningDialog(receiptValidationError);
      return;
    }

    // Show processing state
    setState(() {
      _isProcessing = true;
    });

    try {
      // Save receipt
      await _receiptService.saveReceipt(receiptData);

      // Show success and navigate back
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        await _showSaveSuccessDialog();
      }
      
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        _showErrorDialog(e.toString());
      }
    }
  }

  Future<void> _showSaveSuccessDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 28),
              SizedBox(width: 8),
              Text('บันทึกสำเร็จ!'),
            ],
          ),
          content: const Text('ใบเสร็จของคุณถูกบันทึกเรียบร้อยแล้ว'),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // ปิด dialog
                Navigator.of(context).pop(); // กลับไปหน้าก่อนหน้า
              },
              child: const Text('ตกลง'),
            ),
          ],
        );
      },
    );
  }

  // === CLEAR METHODS ===
  
  Future<void> _showClearConfirmation() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning, color: Colors.orange, size: 28),
              SizedBox(width: 8),
              Text('ยืนยันการล้างข้อมูล'),
            ],
          ),
          content: const Text(
            'คุณต้องการล้างข้อมูลทั้งหมดหรือไม่?\nข้อมูลที่กรอกไว้จะหายไป',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('ยกเลิก'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('ล้างข้อมูล', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      _clearForm();
    }
  }

  void _clearForm() {
    _storeController.clear();
    _dateController.clear();
    _amountController.clear();
    _descriptionController.clear();
    setState(() {
      _imageFile = null;
    });
    
    _showInfoSnackBar("ข้อมูลทั้งหมดถูกล้างเรียบร้อยแล้ว");
  }

  // === NOTIFICATION METHODS ===
  
  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showInfoSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.info, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: Colors.blue,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showErrorDialog(String message) {
    if (mounted) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.error, color: Colors.red, size: 28),
                SizedBox(width: 8),
                Text('เกิดข้อผิดพลาด'),
              ],
            ),
            content: Text(message),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('ตกลง'),
              ),
            ],
          );
        },
      );
    }
  }

  void _showWarningDialog(String message) {
    if (mounted) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.warning, color: Colors.orange, size: 28),
                SizedBox(width: 8),
                Text('คำเตือน'),
              ],
            ),
            content: Text(message),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('เข้าใจแล้ว'),
              ),
            ],
          );
        },
      );
    }
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.help, color: Colors.blue, size: 28),
              SizedBox(width: 8),
              Text('คำแนะนำการใช้งาน'),
            ],
          ),
          content: const SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('📱 สแกนใบเสร็จอัตโนมัติ:'),
                Text('• ใช้ AI ช่วยดึงข้อมูลจากใบเสร็จ'),
                Text('• ถ่ายรูปใบเสร็จให้ชัดเจน'),
                SizedBox(height: 8),
                Text('✏️ กรอกข้อมูลด้วยตนเอง:'),
                Text('• วันที่และจำนวนเงินเป็นข้อมูลที่จำเป็น'),
                Text('• ตรวจสอบข้อมูลก่อนบันทึก'),
                SizedBox(height: 8),
                Text('📸 รูปภาพใบเสร็จ:'),
                Text('• สามารถเพิ่มรูปภาพใบเสร็จได้'),
                Text('• ไม่บังคับ แต่ช่วยให้จำได้ง่าย'),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('เข้าใจแล้ว'),
            ),
          ],
        );
      },
    );
  }

  // === UI BUILD METHODS ===
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('เพิ่มใบเสร็จ'),
      backgroundColor: Theme.of(context).primaryColor,
      foregroundColor: Colors.white,
      elevation: 2,
      actions: [
        IconButton(
          icon: const Icon(Icons.help_outline),
          onPressed: _showHelpDialog,
          tooltip: 'ช่วยเหลือ',
        ),
        IconButton(
          icon: const Icon(Icons.add_a_photo),
          onPressed: _showImageSourceDialog,
          tooltip: 'เลือกรูปภาพ',
        ),
        IconButton(
          icon: const Icon(Icons.clear_all),
          onPressed: (_isProcessing || _isScanning) ? null : _showClearConfirmation,
          tooltip: 'ล้างข้อมูล',
        ),
      ],
    );
  }

  Widget _buildBody() {
    return Stack(
      children: [
        _buildScrollableContent(),
        if (_isProcessing) _buildLoadingOverlay(),
      ],
    );
  }

  Widget _buildScrollableContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // OCR Scanner Section
          ReceiptScannerWidget(
            onScanComplete: _onScanComplete,
            onScanStart: _onScanStart,
            onError: _onScanError,
          ),
          const SizedBox(height: 24),
          
          // Divider
          Row(
            children: [
              const Expanded(child: Divider()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'หรือกรอกข้อมูลด้วยตนเอง',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ),
              const Expanded(child: Divider()),
            ],
          ),
          const SizedBox(height: 24),
          
          _buildImageSection(),
          _buildHeaderCard(),
          const SizedBox(height: 24),
          _buildFormFields(),
          const SizedBox(height: 32),
          _buildActionButtons(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildImageSection() {
    return GestureDetector(
      onTap: _showImageSourceDialog,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: _imageFile != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  _imageFile!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              )
            : _buildImagePlaceholder(),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.add_a_photo,
          size: 50,
          color: Colors.grey[600],
        ),
        const SizedBox(height: 8),
        Text(
          'แตะเพื่อเลือกรูปภาพใบเสร็จ',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '(ไม่บังคับ)',
          style: TextStyle(
            color: Colors.grey[500],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(
              Icons.receipt_long,
              size: 50,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 8),
            Text(
              'กรอกข้อมูลใบเสร็จ',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 4),
            Text(
              'กรุณากรอกข้อมูลใบเสร็จให้ครบถ้วน',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormFields() {
    return Column(
      children: [
        _buildTextField(
          controller: _storeController,
          label: 'ชื่อร้านค้า',
          icon: Icons.store,
          hint: 'เช่น 7-Eleven, ร้านอาหาร ABC',
        ),
        const SizedBox(height: 16),
        
        _buildDateField(),
        const SizedBox(height: 16),
        
        _buildTextField(
          controller: _amountController,
          label: 'จำนวนเงิน (บาท)',
          icon: Icons.attach_money,
          hint: 'เช่น 150.00',
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          isRequired: true,
        ),
        const SizedBox(height: 16),
        
        _buildTextField(
          controller: _descriptionController,
          label: 'รายละเอียด',
          icon: Icons.description,
          hint: 'เช่น อาหาร, เครื่องดื่ม, อุปกรณ์เครื่องเขียน',
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    TextInputType? keyboardType,
    int maxLines = 1,
    bool isRequired = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: isRequired ? '$label *' : label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
    );
  }

  Widget _buildDateField() {
    return TextFormField(
      controller: _dateController,
      readOnly: true,
      onTap: _selectDate,
      decoration: InputDecoration(
        labelText: 'วันที่ *',
        hintText: 'เลือกวันที่',
        prefixIcon: const Icon(Icons.calendar_today),
        suffixIcon: const Icon(Icons.arrow_drop_down),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Save Button
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: (_isProcessing || _isScanning) ? null : _showSaveConfirmation,
            icon: _isProcessing 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.save),
            label: Text(_isProcessing ? 'กำลังบันทึก...' : 'บันทึกใบเสร็จ'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        
        // Clear Button
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            onPressed: (_isProcessing || _isScanning) ? null : _showClearConfirmation,
            icon: const Icon(Icons.clear_all),
            label: const Text('ล้างข้อมูล'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text(
                  'กำลังบันทึกข้อมูล...',
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
// ReceiptData class definition is removed to avoid duplicate type error.
// Use the ReceiptData class from services/receipt_service.dart. });
