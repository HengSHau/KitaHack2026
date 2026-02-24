import 'package:cloud_firestore/cloud_firestore.dart';

class ChatBackend {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Function to send a message to a specific room
  Future<void> sendMessage(String roomId, String text, String senderId) async {
    if (text.trim().isEmpty) return;

    await _firestore
        .collection('chat_rooms')
        .doc(roomId)
        .collection('messages')
        .add({
      'text': text.trim(),
      'senderId': senderId,
      'timestamp': FieldValue.serverTimestamp(), // Firestore real-time sync
    });
  }

  // Stream to listen for new messages instantly
  Stream<QuerySnapshot> getMessages(String roomId) {
    return _firestore
        .collection('chat_rooms')
        .doc(roomId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }
}