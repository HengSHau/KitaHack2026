import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../backend/chat_backend.dart';

const Color kPrimaryGreen = Color(0xFF00B14F);
const Color kLightGreenBg = Color(0xFFF1F8F3);

class ChatSelectionPage extends StatelessWidget {
  const ChatSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final String myEmail = FirebaseAuth.instance.currentUser?.email ?? "";

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text(
            'Messages',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 26, color: Colors.black),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          bottom: const TabBar(
            labelColor: kPrimaryGreen,
            unselectedLabelColor: Colors.grey,
            indicatorColor: kPrimaryGreen,
            indicatorWeight: 3,
            tabs: [
              Tab(text: "Private Chats"),
              Tab(text: "Carpool Groups"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildPrivateChats(myEmail),

            _buildGroupChats(myEmail),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivateChats(String myEmail) {
    return StreamBuilder<QuerySnapshot>(
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

        // Filter out yourself by checking the 'email' field in the document
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
    );
  }

  Widget _buildGroupChats(String myEmail) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Groups')
          .where('participants', arrayContains: myEmail)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text("Error loading groups."));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              "You haven't joined any carpools yet.",
              style: TextStyle(color: Colors.grey.shade600),
            )
          );
        }

        final docs = snapshot.data!.docs;

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final String groupName = data['groupName'] ?? "Carpool Group";
            final String groupId = docs[index].id;
            final String lastMessage = data['lastMessage'] ?? "Tap to view messages";
            final List participants = data['participants'] ?? [];

            return ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              leading: CircleAvatar(
                radius: 26,
                backgroundColor: Colors.orange.withOpacity(0.15),
                child: const Icon(Icons.groups, color: Colors.orange),
              ),
              title: Row(
                children: [
                  Expanded(
                    child:Text(
                      groupName,
                      style:const TextStyle(fontWeight:FontWeight.bold),
                      overflow:TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width:8),
                    Text("(${participants.length})", style: const TextStyle(color: Colors.grey, fontSize: 12)),                ],
              ),
              subtitle: Text(
                lastMessage,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.grey),
              ),
              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GroupMessagingPage(
                      groupId: groupId,
                      groupName: groupName,
                    ),
                  ),
                );
              },
            );
          },
        );
      },
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

class GroupMessagingPage extends StatefulWidget {
  final String groupId;
  final String groupName;

  const GroupMessagingPage({super.key, required this.groupId, required this.groupName});

  @override
  State<GroupMessagingPage> createState() => _GroupMessagingPageState();
}

class _GroupMessagingPageState extends State<GroupMessagingPage> {
  final TextEditingController _messageController = TextEditingController();
  final ChatBackend _chatBackend = ChatBackend();

  void _sendGroupMessage() async {
    final String text = _messageController.text.trim();
    if (text.isEmpty) return;
      
    final String myEmail = FirebaseAuth.instance.currentUser?.email ?? "Unknown";
    
    _messageController.clear();

    try {
      await _chatBackend.sendGroupMessage(widget.groupId, text, myEmail);
      print("Message sent successfully.");
    } catch (e) {
      print("FIREBASE ERROR:$e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to send: $e"),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } 
  }

  @override
  Widget build(BuildContext context) {
    final String myEmail = FirebaseAuth.instance.currentUser?.email ?? "Unknown";

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.groupName, style: const TextStyle(color: Colors.black, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('Groups')
                  .doc(widget.groupId)
                  .collection('Messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                    return const Center(child: Text("Error loading messages."));
                }
                
                if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                }

                var docs = snapshot.data?.docs ?? [];
                
                if (docs.isEmpty) {
                    return const Center(child: Text("Say hi to your carpool group!"));
                }

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    var data = docs[index].data() as Map<String, dynamic>;
                    bool isMe = data['sender'] == myEmail;
                    
                    String senderName = (data['sender'] as String).split('@').first; 

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Column(
                        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                        children: [
                          if (!isMe) 
                            Padding(
                              padding: const EdgeInsets.only(left: 8, bottom: 4),
                              child: Text(senderName, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                            ),
                          Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: isMe ? kPrimaryGreen : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              data['text'] ?? "",
                              style: TextStyle(color: isMe ? Colors.white : Colors.black87, fontSize: 15),
                            ),
                          ),
                        ],
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
                        hintText: "Message group...",
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      onSubmitted: (_) => _sendGroupMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: kPrimaryGreen,
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white, size: 20),
                      onPressed: _sendGroupMessage,
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