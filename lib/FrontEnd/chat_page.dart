import 'package:flutter/material.dart';

const Color kPrimaryGreen = Color(0xFF00B14F);
const Color kLightGreenBg = Color(0xFFF1F8F3);

class ChatSelectionPage extends StatelessWidget {
  const ChatSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> users = [
      {"name": "Ali (Driver)", "status": "Going to APU Campus", "avatar": "A"},
      {"name": "Sarah (Passenger)", "status": "Waiting at Parkhill", "avatar": "S"},
      {"name": "John (Driver)", "status": "Leaving Pavilion Bukit Jalil", "avatar": "J"},
      {"name": "Mei (Passenger)", "status": "Needs ride to LRT station", "avatar": "M"},
    ];

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
      body: ListView.builder(
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            leading: CircleAvatar(
              radius: 26,
              backgroundColor: kPrimaryGreen.withOpacity(0.2),
              child: Text(
                user["avatar"]!, 
                style: const TextStyle(fontSize: 20, color: kPrimaryGreen, fontWeight: FontWeight.bold)
              ),
            ),
            title: Text(user["name"]!, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(user["status"]!, style: TextStyle(color: Colors.grey.shade600)),
            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatMessagingPage(userName: user["name"]!),
                ),
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
  final List<Map<String, dynamic>> _messages = [
    {"text": "Hi! Are you ready for the carpool?", "isMe": false},
  ];

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;
    setState(() {
      _messages.add({"text": _messageController.text, "isMe": true});
      _messageController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kLightGreenBg,
      appBar: AppBar(
        title: Text(widget.userName, style: const TextStyle(color: Colors.black, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final bool isMe = msg['isMe'];
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
                      msg['text'], 
                      style: TextStyle(color: isMe ? Colors.white : Colors.black87, fontSize: 15)
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Textbox
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
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