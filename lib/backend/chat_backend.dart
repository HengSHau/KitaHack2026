import 'package:cloud_firestore/cloud_firestore.dart';

class ChatBackend {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // UPDATED: Added receiverId and participants for the selection page preview
  Future<void> sendMessage(String text, String myEmail, String contactEmail) async {
    if (text.trim().isEmpty) return;

    // Use a top-level 'Chat' collection to match your ChatSelectionPage logic
    await _firestore.collection('Chat').add({
      'text': text.trim(),
      'sender': myEmail,
      'receiver': contactEmail,
      // CRITICAL: This allows the selection page to find this message
      'participants': [myEmail, contactEmail], 
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false, // For the bold unread status
    });
  }

  // Stream for the messaging page itself
  Stream<QuerySnapshot> getMessages(String myEmail, String contactEmail) {
    return _firestore
        .collection('Chat')
        .where('participants', arrayContains: myEmail)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }
}