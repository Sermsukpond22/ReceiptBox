import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:run_android/services/models/receipt_model.dart';
import 'package:run_android/services/receipt_service.dart';

class DocumentPage extends StatefulWidget {
  @override
  _DocumentPageState createState() => _DocumentPageState();
}

class _DocumentPageState extends State<DocumentPage> with TickerProviderStateMixin {
  final ReceiptService _receiptService = ReceiptService();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  String _searchQuery = '';
  String _sortBy = 'date'; // 'date', 'amount', 'store'
  bool _isAscending = false;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  List<Receipt> _filterAndSortReceipts(List<Receipt> receipts) {
    List<Receipt> filteredReceipts = receipts;
    
    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filteredReceipts = receipts.where((receipt) {
        return receipt.storeName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               receipt.amount.toString().contains(_searchQuery);
      }).toList();
    }
    
    // Sort receipts
    filteredReceipts.sort((a, b) {
      int result = 0;
      switch (_sortBy) {
        case 'date':
          result = a.transactionDate.compareTo(b.transactionDate);
          break;
        case 'amount':
          result = a.amount.compareTo(b.amount);
          break;
        case 'store':
          result = a.storeName.compareTo(b.storeName);
          break;
      }
      return _isAscending ? result : -result;
    });
    
    return filteredReceipts;
  }

  Widget _buildSearchBar() {
    return Container(
      margin: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: TextField(
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        decoration: InputDecoration(
          hintText: 'ค้นหาใบเสร็จ...',
          hintStyle: GoogleFonts.prompt(
            color: Colors.grey[600],
            fontSize: 16,
          ),
          prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: Colors.grey[600]),
                  onPressed: () {
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
        style: GoogleFonts.prompt(fontSize: 16),
      ),
    );
  }

  Widget _buildSortOptions() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Text(
            'เรียงโดย: ',
            style: GoogleFonts.prompt(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildSortChip('date', 'วันที่', Icons.calendar_today),
                  SizedBox(width: 8),
                  _buildSortChip('amount', 'จำนวนเงิน', Icons.attach_money),
                  SizedBox(width: 8),
                  _buildSortChip('store', 'ร้านค้า', Icons.store),
                  SizedBox(width: 8),
                  _buildSortOrderChip(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortChip(String value, String label, IconData icon) {
    bool isSelected = _sortBy == value;
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: isSelected ? Colors.white : Colors.grey[600]),
          SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.prompt(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isSelected ? Colors.white : Colors.grey[700],
            ),
          ),
        ],
      ),
      selected: isSelected,
      selectedColor: Theme.of(context).primaryColor,
      backgroundColor: Colors.grey[100],
      onSelected: (selected) {
        setState(() {
          _sortBy = value;
        });
      },
    );
  }

  Widget _buildSortOrderChip() {
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _isAscending ? Icons.arrow_upward : Icons.arrow_downward,
            size: 16,
            color: Colors.grey[600],
          ),
          SizedBox(width: 4),
          Text(
            _isAscending ? 'น้อย-มาก' : 'มาก-น้อย',
            style: GoogleFonts.prompt(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
      backgroundColor: Colors.grey[100],
      onSelected: (selected) {
        setState(() {
          _isAscending = !_isAscending;
        });
      },
    );
  }

  Widget _buildStatisticsCard(List<Receipt> receipts) {
    double totalAmount = receipts.fold(0, (sum, receipt) => sum + receipt.amount);
    int totalCount = receipts.length;
    double averageAmount = totalCount > 0 ? totalAmount / totalCount : 0;

    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withOpacity(0.3),
            blurRadius: 15,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'สรุปใบเสร็จ',
            style: GoogleFonts.prompt(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'จำนวนใบเสร็จ',
                  totalCount.toString(),
                  Icons.receipt_long,
                ),
              ),
              Container(
                height: 40,
                width: 1,
                color: Colors.white.withOpacity(0.3),
              ),
              Expanded(
                child: _buildStatItem(
                  'ยอดรวม',
                  '฿${NumberFormat('#,##0.00').format(totalAmount)}',
                  Icons.attach_money,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Container(
            height: 1,
            color: Colors.white.withOpacity(0.3),
          ),
          SizedBox(height: 12),
          _buildStatItem(
            'ค่าเฉลี่ย',
            '฿${NumberFormat('#,##0.00').format(averageAmount)}',
            Icons.analytics,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.prompt(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.prompt(
            fontSize: 14,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildReceiptCard(Receipt receipt, int index) {
    final thaiDateFormat = DateFormat('dd MMM yy', 'th_TH');
    
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - _animationController.value)),
          child: Opacity(
            opacity: _animationController.value,
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.15),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    // Navigator.push(context, MaterialPageRoute(builder: (_) => ReceiptDetailPage(receipt: receipt)));
                    print('Tapped on receipt ID: ${receipt.id}');
                  },
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      children: [
                        // Receipt Image or Icon
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.grey[100],
                          ),
                          child: receipt.imageUrl != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    receipt.imageUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) =>
                                        Icon(Icons.broken_image, size: 30, color: Colors.grey),
                                  ),
                                )
                              : Icon(
                                  Icons.receipt_long,
                                  size: 30,
                                  color: Theme.of(context).primaryColor,
                                ),
                        ),
                        SizedBox(width: 16),
                        
                        // Receipt Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                receipt.storeName,
                                style: GoogleFonts.prompt(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[800],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                                  SizedBox(width: 4),
                                  Text(
                                    thaiDateFormat.format(receipt.transactionDate),
                                    style: GoogleFonts.prompt(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '฿${NumberFormat('#,##0.00').format(receipt.amount)}',
                                  style: GoogleFonts.prompt(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Arrow Icon
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.receipt_long,
                  size: 60,
                  color: Colors.grey[400],
                ),
              ),
              SizedBox(height: 24),
              Text(
                _searchQuery.isNotEmpty ? 'ไม่พบใบเสร็จที่ค้นหา' : 'ยังไม่มีใบเสร็จ',
                style: GoogleFonts.prompt(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 12),
              Text(
                _searchQuery.isNotEmpty 
                    ? 'ลองใช้คำค้นหาอื่น' 
                    : 'เมื่อคุณมีใบเสร็จ จะแสดงที่นี่',
                style: GoogleFonts.prompt(
                  fontSize: 16,
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
              if (_searchQuery.isNotEmpty) ...[
                SizedBox(height: 24),
                ElevatedButton.icon(
                  icon: Icon(Icons.clear),
                  label: Text(
                    'ล้างการค้นหา',
                    style: GoogleFonts.prompt(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: () {
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor.withOpacity(0.1),
            Colors.white,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
              strokeWidth: 3,
            ),
            SizedBox(height: 20),
            Text(
              'กำลังโหลดใบเสร็จ...',
              style: GoogleFonts.prompt(
                fontSize: 16,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).primaryColor.withOpacity(0.05),
              Colors.white,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom App Bar
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back_ios, color: Colors.grey[800]),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Expanded(
                      child: Text(
                        'ใบเสร็จของฉัน',
                        style: GoogleFonts.prompt(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.more_vert, color: Colors.grey[800]),
                      onPressed: () {
                        // Show more options
                      },
                    ),
                  ],
                ),
              ),
              
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _receiptService.getUserReceipts(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return _buildLoadingState();
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, size: 60, color: Colors.red[300]),
                            SizedBox(height: 16),
                            Text(
                              'เกิดข้อผิดพลาด',
                              style: GoogleFonts.prompt(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.red[300],
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              '${snapshot.error}',
                              style: GoogleFonts.prompt(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    }

                    final docs = snapshot.data?.docs;
                    if (docs == null || docs.isEmpty) {
                      return Column(
                        children: [
                          _buildSearchBar(),
                          Expanded(child: _buildEmptyState()),
                        ],
                      );
                    }

                    // Convert documents to Receipt objects
                    final receipts = docs.map((doc) => Receipt.fromFirestore(doc)).toList();
                    final filteredReceipts = _filterAndSortReceipts(receipts);

                    return Column(
                      children: [
                        _buildSearchBar(),
                        _buildSortOptions(),
                        SizedBox(height: 8),
                        _buildStatisticsCard(filteredReceipts),
                        Expanded(
                          child: filteredReceipts.isEmpty
                              ? _buildEmptyState()
                              : ListView.builder(
                                  padding: EdgeInsets.only(bottom: 20),
                                  itemCount: filteredReceipts.length,
                                  itemBuilder: (context, index) {
                                    return _buildReceiptCard(filteredReceipts[index], index);
                                  },
                                ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      
    );
  }
}