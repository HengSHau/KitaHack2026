import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatBackend {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> sendMessage(String text, String myEmail, String contactEmail) async {
    if (text.trim().isEmpty) return;

    await _firestore.collection('Chat').add({
      'text': text.trim(),
      'sender': myEmail,
      'receiver': contactEmail,
      'participants': [myEmail, contactEmail], 
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false, // For the bold unread status
    });
  }

  Future<String> createGroupChat(String groupName, List<String> participants) async {
    final String myEmail = FirebaseAuth.instance.currentUser?.email ?? "";
    
    // Ensure the person creating the group is included in the chat
    if (!participants.contains(myEmail)) {
      participants.add(myEmail);
    }

    var docRef = await _firestore.collection('Groups').add({
      'groupName': groupName,
      'participants': participants,
      'timestamp': FieldValue.serverTimestamp(),
      'lastMessage': 'Group created',
    });

    return docRef.id; 
  }

  // Sends a text to the specific group
  Future<void> sendGroupMessage(String groupId, String text, String senderEmail) async {
    if (text.trim().isEmpty) return;

    // Add message to the group's subcollection
    await _firestore.collection('Groups').doc(groupId).collection('Messages').add({
      'text': text.trim(),
      'sender': senderEmail,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Update the 'lastMessage' so the chat list preview updates
    await _firestore.collection('Groups').doc(groupId).update({
      'lastMessage': text.trim(),
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}