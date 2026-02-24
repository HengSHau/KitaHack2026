import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

const Color kPrimaryGreen = Color(0xFF00B14F);
const Color kLightGreenBg = Color(0xFFF1F8F3);

class ChatSelectionPage extends StatelessWidget {
  const ChatSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Unique Key: Your Email
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
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Error loading users: ${snapshot.error}"));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No users found."));
          }

          // FIXED: Filter out yourself by checking the 'email' field in the document
          final docs = snapshot.data!.docs.where((doc) {
            final userData = doc.data() as Map<String, dynamic>;
            final String emailInDb = userData['email'] ?? ""; 
            return emailInDb != myEmail; 
          }).toList();

          if (docs.isEmpty) {
            return const Center(child: Text("No other users available."));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final userData = docs[index].data() as Map<String, dynamic>;
              final String name = userData['username'] ?? "User";
              final String email = userData['email'] ?? docs[index].id;

              return ChatContactTile(
                contactName: name,
                contactEmail: email,
                myEmail: myEmail,
              );
            },
          );
        },
      ),
    );
  }
}

class ChatContactTile extends StatelessWidget {
  final String contactName;
  final String contactEmail;
  final String myEmail;

  const ChatContactTile({
    super.key,
    required this.contactName,
    required this.contactEmail,
    required this.myEmail,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      // Listen for messages where I am a participant
      stream: FirebaseFirestore.instance
          .collection('Chat')
          .where('participants', arrayContains: myEmail)
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          // If previews are blank, check browser console (F12) for index link
          print("Preview Error: ${snapshot.error}");
          return const SizedBox.shrink(); 
        }

        String lastMessage = ""; 
        bool isUnread = false;

        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          // Isolate the conversation with this specific contact
          final relevantDocs = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final List participants = data['participants'] ?? [];
            return participants.contains(contactEmail);
          }).toList();

          if (relevantDocs.isNotEmpty) {
            final data = relevantDocs.first.data() as Map<String, dynamic>;
            lastMessage = data['text'] ?? "";
            // BOLD LOGIC: Sent to me and isRead is false
            isUnread = data['receiver'] == myEmail && (data['isRead'] == false);
          } else {
            lastMessage = "Start a conversation"; 
          }
        }

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          leading: CircleAvatar(
            radius: 26,
            backgroundColor: kPrimaryGreen.withOpacity(0.2),
            child: Text(contactName.isNotEmpty ? contactName[0].toUpperCase() : "U", 
              style: const TextStyle(fontSize: 20, color: kPrimaryGreen, fontWeight: FontWeight.bold)),
          ),
          title: Text(contactName, 
            style: TextStyle(fontWeight: isUnread ? FontWeight.w900 : FontWeight.bold)),
          subtitle: Text(
            lastMessage,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isUnread ? Colors.black : Colors.grey,
              fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          trailing: isUnread 
            ? const CircleAvatar(radius: 5, backgroundColor: kPrimaryGreen) 
            : const Icon(Icons.chevron_right, color: Colors.grey),
          onTap: () async {
            // MARK AS READ: Clear the bold status
            var unread = await FirebaseFirestore.instance
              .collection('Chat')
              .where('sender', isEqualTo: contactEmail)
              .where('receiver', isEqualTo: myEmail)
              .where('isRead', isEqualTo: false)
              .get();

            for (var doc in unread.docs) {
              await doc.reference.update({'isRead': true});
            }

            if (context.mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatMessagingPage(
                    userName: contactName,
                    userEmail: contactEmail,
                  ),
                ),
              );
            }
          },
        );
      },
    );
  }
}

class ChatMessagingPage extends StatefulWidget {
  final String userName;
  final String userEmail;

  const ChatMessagingPage({super.key, required this.userName, required this.userEmail});

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

    // Data Bridge: Saving participants and isRead
    await FirebaseFirestore.instance.collection('Chat').add({
      'text': text,
      'sender': myEmail,
      'receiver': widget.userEmail,
      'participants': [myEmail, widget.userEmail],
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
    });
  }

  @override
  Widget build(BuildContext context) {
    final String myEmail = FirebaseAuth.instance.currentUser?.email ?? "Unknown";

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
                  .where('participants', arrayContains: myEmail)
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  print("Messaging Error: ${snapshot.error}");
                  return const Center(child: Text("Error: Check Browser Console (F12)"));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = (snapshot.data?.docs ?? []).where((doc) {
                   final data = doc.data() as Map<String, dynamic>;
                   return data['participants'].contains(widget.userEmail);
                }).toList();

                if (docs.isEmpty) {
                  return const Center(child: Text("Say Hi to Start Conversation!"));
                }

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
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