import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:run_android/Screen/Pages/ReceiptPage.dart/Widgets/AddReceipt_Appbar.dart';
import 'package:run_android/Screen/Pages/ReceiptPage.dart/Widgets/action_buttons.dart';
import 'package:run_android/Screen/Pages/ReceiptPage.dart/Widgets/receipt_form.dart';
import 'package:run_android/Screen/Pages/ReceiptPage.dart/Widgets/receipt_image_section.dart';
import 'package:run_android/Screen/Pages/ReceiptPage.dart/Widgets/ui_utils.dart';
import 'package:run_android/services/OCR-service/receipt_ocr_result.dart';
import 'package:run_android/services/OCR-service/receipt_service.dart';
import 'package:run_android/Screen/Pages/ReceiptPage.dart/Widgets/receipt_scanner_widget.dart';

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
  String? _selectedCategoryId; // Add this line for category ID

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
    _storeController = TextEditingController();
    _dateController = TextEditingController();
    _amountController = TextEditingController();
    _descriptionController = TextEditingController();
    _receiptService = ReceiptService();
    _picker = ImagePicker();
    // Initialize date controller with current date for convenience
    _dateController.text = DateFormat('dd/MM/yyyy').format(DateTime.now());
  }

  @override
  void dispose() {
    _storeController.dispose();
    _dateController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // === LOGIC HANDLERS ===

  void _onScanStart() {
    setState(() => _isScanning = true);
    UiUtils.showInfoSnackBar(context, "กำลังสแกนใบเสร็จ...");
  }

  void _onScanComplete(ReceiptOCRResult result) {
    setState(() => _isScanning = false);
    if (result.isNotEmpty) {
      _fillFormFromOCR(result);
      UiUtils.showScanResultDialog(context, result);
    } else {
      UiUtils.showWarningDialog(context, "ไม่พบข้อมูลใบเสร็จ กรุณากรอกข้อมูลด้วยตนเอง");
    }
  }

  void _onScanError(String error) {
    setState(() => _isScanning = false);
    UiUtils.showErrorDialog(context, "เกิดข้อผิดพลาดในการสแกน: $error");
  }

  void _fillFormFromOCR(ReceiptOCRResult result) {
    if (result.storeName.isNotEmpty) _storeController.text = result.storeName;
    if (result.amount != null) _amountController.text = result.amount!.toStringAsFixed(2);
    if (result.date != null) _dateController.text = DateFormat('dd/MM/yyyy').format(result.date!);
    if (result.description.isNotEmpty) _descriptionController.text = result.description;
    // Note: OCR usually doesn't provide category, so we don't set _selectedCategoryId here.
    // User will have to pick it manually or it will default to null.
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(source: source, maxWidth: 1024, maxHeight: 1024, imageQuality: 85);
      if (pickedFile != null) {
        setState(() => _imageFile = File(pickedFile.path));
        UiUtils.showSuccessSnackBar(context, "เพิ่มรูปภาพใบเสร็จเรียบร้อยแล้ว");
      }
    } catch (e) {
      UiUtils.showErrorDialog(context, 'เกิดข้อผิดพลาดในการเลือกรูปภาพ: $e');
    }
  }

  void _removeImage() {
    setState(() => _imageFile = null);
    UiUtils.showInfoSnackBar(context, "รูปภาพใบเสร็จถูกลบออกแล้ว");
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateFormat('dd/MM/yyyy').parse(_dateController.text), // Use current date in controller as initial
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      _dateController.text = DateFormat('dd/MM/yyyy').format(picked);
    }
  }

  void _onCategorySelected(String? categoryId) {
    setState(() {
      _selectedCategoryId = categoryId;
    });
  }

  Future<void> _handleSave() async {
  final validationError = _validateForm();
  if (validationError != null) {
    UiUtils.showWarningDialog(context, validationError);
    return;
  }

  final confirmed = await UiUtils.showSaveConfirmation(context);
  if (confirmed != true) return;

  setState(() => _isProcessing = true);

  try {
    final receiptData = _createReceiptData();
    await _receiptService.saveReceipt(receiptData);

    if (!mounted) return;

    // แทนที่ showSaveSuccessDialog ด้วย dialog แบบเลือก
    final choice = await UiUtils.showSaveSuccessChoiceDialog(context);
    
    if (!mounted) return;

    if (choice == 'add_more') {
      // ล้างฟอร์มเพื่อเพิ่มใบเสร็จใหม่
      _handleClear();
    } else if (choice == 'go_to_document') {
      // ไปหน้ารายการใบเสร็จ (เปลี่ยนชื่อ route ตามแอปของคุณ)
      Navigator.of(context).pushReplacementNamed('/documentPage');
    }

  } catch (e) {
    if (mounted) UiUtils.showErrorDialog(context, e.toString());
  } finally {
    if (mounted) setState(() => _isProcessing = false);
  }
}

  Future<void> _handleClear() async {
    final confirmed = await UiUtils.showClearConfirmation(context);
    if (confirmed == true) {
      _storeController.clear();
      _dateController.text = DateFormat('dd/MM/yyyy').format(DateTime.now()); // Reset date
      _amountController.clear();
      _descriptionController.clear();
      setState(() {
        _imageFile = null;
        _selectedCategoryId = null; // Clear selected category
      });
      UiUtils.showInfoSnackBar(context, "ข้อมูลทั้งหมดถูกล้างเรียบร้อยแล้ว");
    }
  }

  String? _validateForm() {
    if (!_receiptService.isUserLoggedIn) return 'กรุณาเข้าสู่ระบบก่อนใช้งาน';
    if (_amountController.text.isEmpty || _dateController.text.isEmpty) return 'กรุณากรอกวันที่และจำนวนเงิน';
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) return 'กรุณากรอกจำนวนเงินที่ถูกต้อง';
    try {
      DateFormat('dd/MM/yyyy').parse(_dateController.text);
    } catch (e) {
      return 'กรุณากรอกวันที่ในรูปแบบ วว/ดด/ปปปป';
    }
    return null;
  }

  ReceiptData _createReceiptData() {
    return ReceiptData(
      storeName: _storeController.text,
      description: _descriptionController.text,
      amount: double.parse(_amountController.text),
      transactionDate: DateFormat('dd/MM/yyyy').parse(_dateController.text),
      imageFile: _imageFile,
      categoryId: _selectedCategoryId, // Pass the selected category ID here
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isActionDisabled = _isProcessing || _isScanning;
    return Scaffold(
      appBar: AddReceiptAppBar(
        isActionDisabled: isActionDisabled,
        onHelpPressed: () => UiUtils.showHelpDialog(context),
        onImagePressed: () => UiUtils.showImageSourceBottomSheet(
          context: context,
          hasImage: _imageFile != null,
          onCamera: () => _pickImage(ImageSource.camera),
          onGallery: () => _pickImage(ImageSource.gallery),
          onRemove: _removeImage,
        ),
        onClearPressed: _handleClear,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ReceiptScannerWidget(
                  onScanComplete: _onScanComplete,
                  onScanStart: _onScanStart,
                  onError: _onScanError,
                ),
                const SizedBox(height: 24),
                Row(children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text('หรือกรอกข้อมูลด้วยตนเอง', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                  ),
                  const Expanded(child: Divider()),
                ]),
                const SizedBox(height: 24),
                ReceiptImageSection(
                  imageFile: _imageFile,
                  onTap: () => UiUtils.showImageSourceBottomSheet(
                    context: context,
                    hasImage: _imageFile != null,
                    onCamera: () => _pickImage(ImageSource.camera),
                    onGallery: () => _pickImage(ImageSource.gallery),
                    onRemove: _removeImage,
                  ),
                ),
                const SizedBox(height: 16),
                ReceiptForm(
                  storeController: _storeController,
                  dateController: _dateController,
                  amountController: _amountController,
                  descriptionController: _descriptionController,
                  onSelectDate: _selectDate,
                  onCategorySelected: _onCategorySelected, // Pass the callback here
                  initialCategoryId: _selectedCategoryId, // Pass the selected category ID here
                ),
                const SizedBox(height: 32),
                ActionButtons(
                  isProcessing: _isProcessing,
                  isScanning: _isScanning,
                  onSave: _handleSave,
                  onClear: _handleClear,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
          if (_isProcessing) UiUtils.buildLoadingOverlay(),
        ],
      ),
    );
  }
}