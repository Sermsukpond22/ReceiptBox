import 'package:flutter/material.dart';
import 'package:run_android/models/category_model.dart';
import 'package:run_android/services/categories_service.dart';


class ReceiptForm extends StatefulWidget {
  final TextEditingController storeController;
  final TextEditingController dateController;
  final TextEditingController amountController;
  final TextEditingController descriptionController;
  final VoidCallback onSelectDate;
  final ValueChanged<String?> onCategorySelected;
  final String? initialCategoryId;

  const ReceiptForm({
    super.key,
    required this.storeController,
    required this.dateController,
    required this.amountController,
    required this.descriptionController,
    required this.onSelectDate,
    required this.onCategorySelected,
    required this.initialCategoryId,
  });

  @override
  State<ReceiptForm> createState() => _ReceiptFormState();
}

class _ReceiptFormState extends State<ReceiptForm> {
  List<Category> _categories = [];
  bool _isLoadingCategories = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  void _loadCategories() {
    final categoryService = CategoryService();

    if (!categoryService.isUserLoggedIn) {
      // ผู้ใช้ยังไม่ login ก็หยุดหมุนเลย
      setState(() {
        _isLoadingCategories = false;
      });
      return;
    }

    try {
      categoryService.getAllCategoriesForUser().listen(
        (categories) {
          print('✅ โหลดหมวดหมู่สำเร็จ ${categories.length} รายการ');
          if (mounted) {
            setState(() {
              _categories = categories;
              _isLoadingCategories = false;
            });
          }
        },
        onError: (error) {
          print('❌ Error loading categories: $error');
          if (mounted) {
            setState(() => _isLoadingCategories = false);
          }
        },
      );
    } catch (e) {
      print('❌ Exception: $e');
      if (mounted) {
        setState(() => _isLoadingCategories = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- ร้านค้า ---
        TextField(
          controller: widget.storeController,
          decoration: const InputDecoration(labelText: 'ชื่อร้านค้า'),
        ),
        const SizedBox(height: 12),

         // --- หมวดหมู่ ---
        _isLoadingCategories
            ? const Center(child: CircularProgressIndicator())
            : DropdownButtonFormField<String>(
                value: widget.initialCategoryId,
                items: _categories.map((category) {
                  return DropdownMenuItem<String>(
                    value: category.id,
                    child: Text(category.name),
                  );
                }).toList(),
                onChanged: widget.onCategorySelected,
                decoration: const InputDecoration(labelText: 'หมวดหมู่'),
              ),
        const SizedBox(height: 12),

        // --- จำนวนเงิน ---
        TextField(
          controller: widget.amountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'จำนวนเงิน (บาท)'),
        ),
        const SizedBox(height: 12),

        // --- วันที่ ---
        TextField(
          controller: widget.dateController,
          readOnly: true,
          decoration: const InputDecoration(labelText: 'วันที่'),
          onTap: widget.onSelectDate,
        ),
        const SizedBox(height: 12),

        // --- รายละเอียดเพิ่มเติม ---
        TextField(
          controller: widget.descriptionController,
          maxLines: 2,
          decoration: const InputDecoration(labelText: 'รายละเอียดเพิ่มเติม'),
        ),
        const SizedBox(height: 16),

       
      ],
    );
  }
}
