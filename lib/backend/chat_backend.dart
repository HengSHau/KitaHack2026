import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  // 2. MISSING METHOD: Sends a text to the specific group (Used by GroupMessagingPage)
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