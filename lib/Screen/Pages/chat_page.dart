import 'package:flutter/material.dart';
import 'package:run_android/services/chat_logs_service.dart';
import 'package:run_android/services/gemini_service.dart';
import 'package:firebase_auth/firebase_auth.dart';


class ChatPage extends StatefulWidget {
  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  final GeminiService _geminiService = GeminiService();
  final ChatLogsService _chatLogsService = ChatLogsService();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, String>> _messages = [];
  bool _isLoading = false;

  void _sendMessage() async {
  String message = _controller.text.trim();
  if (message.isEmpty) return;

  setState(() {
    _messages.add({"role": "user", "text": message});
    _isLoading = true;
    _controller.clear();
  });

  _scrollToBottom();

  // ใช้ userId ที่ได้จาก Firebase Authentication
  String userId = FirebaseAuth.instance.currentUser?.uid ?? 'guest_user'; // กำหนด userId หากไม่ได้ล็อกอิน

  String botReply = await _geminiService.getGeminiResponse(userId, message);

  setState(() {
    _messages.add({"role": "bot", "text": botReply});
    _isLoading = false;
  });

  _scrollToBottom();

  // บันทึกข้อมูลการแชทลง Firebase
  await _chatLogsService.logChat(
    userId: userId,  // ส่ง userId ที่ได้จากระบบจริง
    message: message,
    response: botReply,
  );
}


  void _scrollToBottom() {
    Future.delayed(Duration(milliseconds: 100), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 100,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  Widget _buildChatBubble(String text, bool isUser) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Card(
        color: isUser ? Colors.blue[100] : Colors.grey[200],
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.symmetric(vertical: 6, horizontal: 10),
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment:
                isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isUser ? Icons.person : Icons.smart_toy,
                    size: 16,
                    color: Colors.grey[700],
                  ),
                  SizedBox(width: 6),
                  Text(
                    isUser ? 'คุณ' : 'แชทบอท',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 4),
              Text(
                text,
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F7FA),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
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
          ),
          if (_isLoading) Padding(
            padding: const EdgeInsets.all(8.0),
            child: CircularProgressIndicator(),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'พิมพ์คำถามของคุณ...',
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding:
                          EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Colors.blue[600],
                  child: IconButton(
                    icon: Icon(Icons.send, color: Colors.white),
                    onPressed: _isLoading ? null : _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
void initState() {
  super.initState();
  // รอฟังว่า Firebase Auth พร้อมหรือยัง
  FirebaseAuth.instance.authStateChanges().listen((user) {
    if (user != null) {
      print('✅ Logged in as: ${user.uid}');
      _loadChatHistory();  // โหลดแชทเมื่อ login แล้วเท่านั้น
    } else {
      print('⚠️ ยังไม่ได้ login');
    }
  });
}

Future<void> _loadChatHistory() async {
  String userId = FirebaseAuth.instance.currentUser?.uid ?? 'guest_user';

  try {
    List<Map<String, String>> history = await _chatLogsService.getChatHistory(userId);
    setState(() {
      _messages = history;
    });

    _scrollToBottom();
  } catch (e) {
    print('❗ ไม่สามารถโหลดประวัติแชท: $e');
  }
}

}
