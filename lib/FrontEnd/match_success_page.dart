import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_page.dart'; 
import '../backend/chat_backend.dart';

const Color kThemeGreen = Color(0xFF2ECC71);

class MatchSuccessPage extends StatefulWidget {
  final List<Map<String, dynamic>> matchedUsers;
  final String origin;
  final String destination;
  final String date;
  final String time;

  const MatchSuccessPage({
    super.key,
    required this.matchedUsers,
    required this.origin,
    required this.destination,
    required this.date,
    required this.time,
  });


  @override
  State<MatchSuccessPage> createState() => _MatchSuccessPageState();
}

class _MatchSuccessPageState extends State<MatchSuccessPage> {
  bool _isLoading = false;
  final ChatBackend _chatBackend = ChatBackend();


  void _handleChatNavigation() async {
    setState(() => _isLoading = true);
    
    bool isGroup = widget.matchedUsers.length > 1;

    try {
      if (isGroup) {
        // Safely extract emails
        List<String> passengerEmails = widget.matchedUsers.map((u) => (u['email'] ?? "").toString()).toList();
        
        String groupName = "${widget.origin}_${widget.destination}_${widget.date}_${widget.time}";
        String newGroupId = await _chatBackend.createGroupChat(groupName, passengerEmails);

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => GroupMessagingPage( 
                groupId: newGroupId,
                groupName: groupName,
              ),
            ),
          );
        }
      } else {
        // Safely extract 1-on-1 details
        String contactEmail = widget.matchedUsers[0]['email'] ?? "Unknown";
        String contactName = widget.matchedUsers[0]['name'] ?? "Passenger";
        
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ChatMessagingPage(
                userName: contactName,
                userEmail: contactEmail,
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error creating chat: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isGroup = widget.matchedUsers.length > 1;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.groups_rounded, size: 80, color: kThemeGreen),
              const SizedBox(height: 16),
              Text(
                isGroup ? "Group Found!" : "Match Found!",
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                "You are matched with ${widget.matchedUsers.length} passengers\nheading to the same destination.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              const SizedBox(height: 32),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                ),
                child: Column(
                  children: [
                    const Text("Ride Members", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 15),
                    
                    // FIXED: Safe extraction of data to prevent crashes
                    ...widget.matchedUsers.map((user) {
                      String name = user['name'] ?? "Passenger";
                      String personality = user['personality'] ?? "Unknown";
                      String initial = name.isNotEmpty ? name[0].toUpperCase() : "P";

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: kThemeGreen.withOpacity(0.1),
                              child: Text(initial, style: const TextStyle(color: kThemeGreen, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                            ),
                            _buildPersonalityTag(personality),
                          ],
                        ),
                      );
                    }).toList(),
                    
                    const Divider(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (widget.matchedUsers.length < 4) ...[
                          const Icon(Icons.info_outline, size: 16, color: Colors.orange),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          "${widget.matchedUsers.length}/4 Seats Filled",
                          style: TextStyle(
                            color: widget.matchedUsers.length == 4 ? Colors.green : Colors.orange,
                            fontSize: 12,
                            fontWeight: FontWeight.bold)),
                      ],
                    )
                  ],
                ),
              ),

              const SizedBox(height: 40),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleChatNavigation, 
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kThemeGreen,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isLoading 
                        ? const SizedBox(
                            height: 20, 
                            width: 20, 
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                          )
                        : Text(
                            isGroup ? "Join Group Chat" : "Chat Now",
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPersonalityTag(String type) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: kThemeGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        type,
        style: const TextStyle(color: kThemeGreen, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}