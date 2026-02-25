import 'package:flutter/material.dart';
import 'chat_page.dart'; 

const Color kThemeGreen = Color(0xFF2ECC71);

class MatchSuccessPage extends StatelessWidget {
  const MatchSuccessPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> matchedUsers = [
      {"name": "Sarah", "personality": "Extroverted"},
      {"name": "Jason", "personality": "Introverted"},
      {"name": "Mei", "personality": "Ambivert"},
    ];

    bool isGroup = matchedUsers.length > 1;

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
                "You are matched with ${matchedUsers.length} passengers\nheading to the same destination.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              const SizedBox(height: 32),

              // Partner(s) matched
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
                    
                    ...matchedUsers.map((user) => Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: kThemeGreen.withOpacity(0.1),
                            child: Text(user['name']![0], style: const TextStyle(color: kThemeGreen, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Text(user['name']!, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                          ),
                          // Personality
                          _buildPersonalityTag(user['personality']!),
                        ],
                      ),
                    )).toList(),
                    
                    const Divider(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (matchedUsers.length < 4) ...[
                          Icon(Icons.info_outline, size: 16, color: Colors.orange),
                          SizedBox(width: 8),
                        ],
                        Text(
                          "${matchedUsers.length}/4 Seats Filled",
                          style: TextStyle(
                            color: matchedUsers.length == 4 ? Colors.green : Colors.orange,
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
                      onPressed: () {
                        // Navigator.push(
                        //   context,
                        //   MaterialPageRoute(
                        //     builder: (context) => ChatMessagingPage(
                        //       userName: isGroup ? "Ride Group (${matchedUsers.length + 1})" : matchedUsers[0]['name']!,
                        //     ),
                        //   ),
                        // );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kThemeGreen,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
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