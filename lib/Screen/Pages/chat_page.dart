import 'package:flutter/material.dart';
import 'package:run_android/services/chat_logs_service.dart';
import 'package:run_android/services/gemini_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatPage extends StatefulWidget {
  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  // Controllers และ Services
  final TextEditingController _controller = TextEditingController();
  final GeminiService _geminiService = GeminiService();
  final ChatLogsService _chatLogsService = ChatLogsService();
  final ScrollController _scrollController = ScrollController();

  // State Variables
  List<Map<String, String>> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _setupAuthListener();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F7FA),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildChatList(),
          _buildLoadingIndicator(),
          _buildMessageInput(),
        ],
      ),
    );
  }

  // === APP BAR SECTION ===
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Row(
        children: [
          Icon(Icons.smart_toy, color: Colors.blue[600]),
          SizedBox(width: 8),
          Text('แชทบอท', style: TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
      backgroundColor: Colors.white,
      elevation: 1,
      actions: [
        IconButton(
          icon: Icon(Icons.refresh),
          onPressed: _refreshChat,
          tooltip: 'รีเฟรชแชท',
        ),
        IconButton(
          icon: Icon(Icons.clear_all),
          onPressed: _clearChat,
          tooltip: 'ล้างแชท',
        ),
      ],
    );
  }

  // === CHAT LIST SECTION ===
  Widget _buildChatList() {
    return Expanded(
      child: _messages.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.only(top: 10, bottom: 10),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return _buildChatBubble(
                  msg['text'] ?? '',
                  msg['role'] == 'user',
                );
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            'เริ่มการสนทนาของคุณ',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'พิมพ์คำถามด้านล่างเพื่อเริ่มแชท',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  // === CHAT BUBBLE SECTION ===
  Widget _buildChatBubble(String text, bool isUser) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 4, horizontal: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Card(
          color: isUser ? Colors.blue[100] : Colors.grey[200],
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                _buildMessageHeader(isUser),
                SizedBox(height: 6),
                _buildMessageText(text),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageHeader(bool isUser) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 8,
          backgroundColor: isUser ? Colors.blue[600] : Colors.grey[600],
          child: Icon(
            isUser ? Icons.person : Icons.smart_toy,
            size: 12,
            color: Colors.white,
          ),
        ),
        SizedBox(width: 6),
        Text(
          isUser ? 'คุณ' : 'แชทบอท',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }

  Widget _buildMessageText(String text) {
    return SelectableText(
      text,
      style: TextStyle(
        fontSize: 16,
        height: 1.4,
      ),
    );
  }

  // === LOADING INDICATOR SECTION ===
  Widget _buildLoadingIndicator() {
    return _isLoading
        ? Container(
            padding: EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 12),
                Text(
                  'กำลังตอบ...',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          )
        : SizedBox.shrink();
  }

  // === MESSAGE INPUT SECTION ===
  Widget _buildMessageInput() {
    return Container(
      padding: EdgeInsets.fromLTRB(12, 8, 12, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(25),
                ),
                child: TextField(
                  controller: _controller,
                  maxLines: null,
                  textInputAction: TextInputAction.newline,
                  onSubmitted: (_) => _sendMessage(),
                  decoration: InputDecoration(
                    hintText: 'พิมพ์คำถามของคุณ...',
                    contentPadding: EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    border: InputBorder.none,
                    hintStyle: TextStyle(color: Colors.grey[500]),
                  ),
                ),
              ),
            ),
            SizedBox(width: 8),
            _buildSendButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildSendButton() {
    return Container(
      decoration: BoxDecoration(
        color: _isLoading ? Colors.grey[400] : Colors.blue[600],
        borderRadius: BorderRadius.circular(25),
      ),
      child: IconButton(
        icon: Icon(
          _isLoading ? Icons.hourglass_empty : Icons.send,
          color: Colors.white,
        ),
        onPressed: _isLoading ? null : _sendMessage,
      ),
    );
  }

  // === AUTHENTICATION SECTION ===
  void _setupAuthListener() {
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        print('✅ Logged in as: ${user.uid}');
        _loadChatHistory();
      } else {
        print('⚠️ ยังไม่ได้ login');
        _handleGuestMode();
      }
    });
  }

  void _handleGuestMode() {
    // สำหรับผู้ใช้ที่ยังไม่ได้ login
    setState(() {
      _messages = [];
    });
  }

  // === CHAT FUNCTIONALITY SECTION ===
  Future<void> _sendMessage() async {
    String message = _controller.text.trim();
    if (message.isEmpty || _isLoading) return;

    // เพิ่มข้อความของผู้ใช้
    _addUserMessage(message);

    // เรียก API และเพิ่มการตอบกลับ
    await _processMessage(message);
  }

  void _addUserMessage(String message) {
    setState(() {
      _messages.add({"role": "user", "text": message});
      _isLoading = true;
      _controller.clear();
    });
    _scrollToBottom();
  }

  Future<void> _processMessage(String message) async {
    try {
      String userId = _getCurrentUserId();
      String botReply = await _geminiService.getGeminiResponse(userId, message);

      setState(() {
        _messages.add({"role": "bot", "text": botReply});
      });

      // บันทึกการแชท
      await _saveChatLog(userId, message, botReply);
    } catch (e) {
      _handleError('เกิดข้อผิดพลาดในการส่งข้อความ: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  // === CHAT HISTORY SECTION ===
  Future<void> _loadChatHistory() async {
    try {
      String userId = _getCurrentUserId();
      List<Map<String, String>> history = 
          await _chatLogsService.getChatHistory(userId);
      
      setState(() {
        _messages = history;
      });
      
      _scrollToBottom();
    } catch (e) {
      print('❗ ไม่สามารถโหลดประวัติแชท: $e');
      _handleError('ไม่สามารถโหลดประวัติแชทได้');
    }
  }

  Future<void> _saveChatLog(String userId, String message, String response) async {
    try {
      await _chatLogsService.logChat(
        userId: userId,
        message: message,
        response: response,
      );
    } catch (e) {
      print('❗ ไม่สามารถบันทึกแชท: $e');
    }
  }

  // === UTILITY FUNCTIONS ===
  String _getCurrentUserId() {
    return FirebaseAuth.instance.currentUser?.uid ?? 'guest_user';
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _refreshChat() {
    _loadChatHistory();
  }

  void _clearChat() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('ล้างแชท'),
        content: Text('คุณต้องการล้างแชททั้งหมดหรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _messages.clear();
              });
              Navigator.pop(context);
            },
            child: Text('ล้าง'),
          ),
        ],
      ),
    );
  }

  void _handleError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}