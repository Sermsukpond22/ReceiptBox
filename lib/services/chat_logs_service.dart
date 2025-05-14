import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

class ChatLogsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final uuid = Uuid();

  Future<void> logChat({
    required String userId,
    required String message,
    required String response,
  }) async {
    String chatId = uuid.v4();

    await _firestore.collection('chatbot_logs').doc(chatId).set({
      'ChatID': chatId,
      'UserID': userId,
      'Message': message,
      'Response': response,
      'Timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<List<Map<String, String>>> getChatHistory(String userId) async {
    final snapshot = await _firestore
        .collection('chatbot_logs')
        .where('UserID', isEqualTo: userId)
        .orderBy('Timestamp', descending: false)
        .get();

    List<Map<String, String>> chatHistory = [];

    for (var doc in snapshot.docs) {
      chatHistory.add({"role": "user", "text": doc['Message']});
      chatHistory.add({"role": "bot", "text": doc['Response']});
    }

    return chatHistory;
  }
}
