import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

const Color kPrimaryGreen = Color(0xFF00B14F);
const Color kLightGreenBg = Color(0xFFF1F8F3);

class ChatSelectionPage extends StatelessWidget {
  const ChatSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    // FIXED: Removed the semicolon error and added proper current user check
    final String myEmail = FirebaseAuth.instance.currentUser?.email ?? "";

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Select Contact',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 26, color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      // FIXED: Replaced static ListView with StreamBuilder to use proper Firebase users
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No users found."));
          }

          // Filter out your own account from the list
          final docs = snapshot.data!.docs.where((doc) => doc.id != myEmail).toList();

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final userData = docs[index].data() as Map<String, dynamic>;
              final String name = userData['username'] ?? "User";
              final String avatarLetter = name.isNotEmpty ? name[0].toUpperCase() : "U";

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                leading: CircleAvatar(
                  radius: 26,
                  backgroundColor: kPrimaryGreen.withOpacity(0.2),
                  child: Text(
                    avatarLetter, 
                    style: const TextStyle(fontSize: 20, color: kPrimaryGreen, fontWeight: FontWeight.bold)
                  ),
                ),
                title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text("Available for carpool"),
                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatMessagingPage(userName: name),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class ChatMessagingPage extends StatefulWidget {
  final String userName;
  const ChatMessagingPage({super.key, required this.userName});

  @override
  State<ChatMessagingPage> createState() => _ChatMessagingPageState();
}

class _ChatMessagingPageState extends State<ChatMessagingPage> {
  final TextEditingController _messageController = TextEditingController();

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final String text = _messageController.text.trim();
    final String myEmail = FirebaseAuth.instance.currentUser?.email ?? "Unknown";

    _messageController.clear();

    await FirebaseFirestore.instance.collection('Chat').add({
      'text': text,
      'sender': myEmail,
      'timestamp': FieldValue.serverTimestamp(),
      'receiver': widget.userName,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.userName, style: const TextStyle(color: Colors.black, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('Chat')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("Say Hi to Start Conversation!"));
                }

                final docs = snapshot.data!.docs;
                final String myEmail = FirebaseAuth.instance.currentUser?.email ?? "Unknown";

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;

                    final bool isRelevant = (data['sender'] == myEmail && data['receiver'] == widget.userName) ||
                                           (data['sender'] == widget.userName && data['receiver'] == myEmail);
                    
                    if (!isRelevant) return const SizedBox.shrink();

                    final bool isMe = data['sender'] == myEmail;

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isMe ? kPrimaryGreen : Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(20),
                            topRight: const Radius.circular(20),
                            bottomLeft: Radius.circular(isMe ? 20 : 0),
                            bottomRight: Radius.circular(isMe ? 0 : 20),
                          ),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))
                          ],
                        ),
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                        child: Text(
                          data['text'] ?? "",
                          style: TextStyle(color: isMe ? Colors.white : Colors.black87, fontSize: 15),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)]
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: "Type a message...",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                        filled: true,
                        fillColor: Colors.grey[100],
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      onSubmitted: (value) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: kPrimaryGreen,
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white, size: 20),
                      onPressed: _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}