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
}
