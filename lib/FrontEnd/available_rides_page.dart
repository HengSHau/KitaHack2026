import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'match_in_advance_page.dart';
import 'home_page.dart'; 
import 'chat_page.dart'; // 🚀 必须导入聊天页面，以便跳转

const Color kThemeGreen = Color(0xFF2ECC71);

class AvailableRidesPage extends StatefulWidget {
  final RideRequest currentUser;
  const AvailableRidesPage({super.key, required this.currentUser});

  @override
  State<AvailableRidesPage> createState() => _AvailableRidesPageState();
}

class _AvailableRidesPageState extends State<AvailableRidesPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Rides to ${widget.currentUser.destination}",
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        centerTitle: true,
      ),
      
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('scheduled_rides').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: kThemeGreen));
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text("No rides available yet.\nBe the first to create one!", 
                textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 16)),
            );
          }

          final validDocs = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final String dbDest = (data['destination'] ?? '').toString().trim().toLowerCase();
            final String targetDest = widget.currentUser.destination.trim().toLowerCase();
            return dbDest.contains(targetDest) || targetDest.contains(dbDest);
          }).toList();

          if (validDocs.isEmpty) {
            return Center(
              child: Text("No matching rides found for '${widget.currentUser.destination}'.\nTry searching something else.", 
              textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: validDocs.length,
            itemBuilder: (context, index) {
              final doc = validDocs[index];
              return _buildRideCard(doc, context);
            },
          );
        },
      ),

      floatingActionButton: widget.currentUser.role == 'driver' 
          ? FloatingActionButton(
              backgroundColor: kThemeGreen,
              elevation: 4,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => MatchInAdvancePage(currentUser: widget.currentUser)),
                );
              },
              child: const Icon(Icons.add, color: Colors.white, size: 30),
            )
          : null,
    );
  }

  Widget _buildRideCard(DocumentSnapshot doc, BuildContext context) {
    final data = doc.data() as Map<String, dynamic>;
    final String docId = doc.id;
    
    // Calculate remaining seat(s)
    final List<dynamic> joinedUsers = data['joinedUsers'] ?? [];
    final int joinedCount = joinedUsers.length;
    final int totalSeats = data['seats'] ?? 1;
    final int seatsLeft = totalSeats - joinedCount;
    
    final String currentUserEmail = FirebaseAuth.instance.currentUser?.email ?? "";
    final bool isMyOwnRide = (data['email'] == currentUserEmail);
    final bool hasJoined = joinedUsers.contains(currentUserEmail);
    final bool isFull = seatsLeft <= 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: kThemeGreen.withOpacity(0.15),
                      child: Icon(data['role'] == 'driver' ? Icons.directions_car : Icons.person, color: kThemeGreen),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(data['name'] ?? "Unknown", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text("Personality: ${data['personality']}", style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
                // Show remaining seat(s)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isFull ? Colors.red.withOpacity(0.1) : kThemeGreen.withOpacity(0.1), 
                    borderRadius: BorderRadius.circular(20)
                  ),
                  child: Text(
                    isFull ? "Full" : "$seatsLeft Seats Left",
                    style: TextStyle(
                      color: isFull ? Colors.red : kThemeGreen, 
                      fontWeight: FontWeight.bold, fontSize: 12
                    ),
                  ),
                ),
              ],
            ),
            
            // Show person(s) joined
            if (joinedCount > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8.0, left: 52.0),
                child: Text("👥 $joinedCount person(s) already joined", style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontStyle: FontStyle.italic)),
              ),

            const Padding(padding: EdgeInsets.symmetric(vertical: 12.0), child: Divider()),
            Row(
              children: [
                const Icon(Icons.calendar_month, size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                Text("${data['date']} • ${data['time']}", style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    const Icon(Icons.circle, size: 12, color: kThemeGreen),
                    Container(height: 20, width: 2, color: Colors.grey.shade300),
                    const Icon(Icons.location_on, size: 14, color: Colors.redAccent),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(data['start'] ?? "", style: const TextStyle(fontSize: 14)),
                      const SizedBox(height: 14),
                      Text(data['destination'] ?? "", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            SizedBox(
              width: double.infinity, height: 45,
              child: ElevatedButton(
                // 🚀 这里是核心改动区域
                onPressed: (isMyOwnRide || hasJoined || isFull) ? null : () async {
                  
                  // 1. 弹出 Loading 圈，防止用户狂点
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => const Center(child: CircularProgressIndicator(color: kThemeGreen)),
                  );

                  try {
                    // 2. 将用户加入订单的 joinedUsers
                    await FirebaseFirestore.instance.collection('scheduled_rides').doc(docId).update({
                      'joinedUsers': FieldValue.arrayUnion([currentUserEmail])
                    });
                    
                    // 3. 查找该订单对应的群聊 (通过 rideId)
                    QuerySnapshot groupQuery = await FirebaseFirestore.instance
                        .collection('Groups')
                        .where('rideId', isEqualTo: docId)
                        .limit(1)
                        .get();

                    if (groupQuery.docs.isNotEmpty) {
                      DocumentSnapshot groupDoc = groupQuery.docs.first;
                      String groupId = groupDoc.id;
                      String groupName = groupDoc['groupName'] ?? "Carpool Group";

                      // 4. 将用户加入群聊的 participants
                      await FirebaseFirestore.instance.collection('Groups').doc(groupId).update({
                        'participants': FieldValue.arrayUnion([currentUserEmail])
                      });

                      if (context.mounted) {
                        Navigator.pop(context); // 关掉 Loading
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Successfully joined ${data['name']}'s ride! 🌍"), backgroundColor: Colors.green),
                        );
                        
                        // 5. 跳转到聊天室！
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => GroupMessagingPage(
                              groupId: groupId,
                              groupName: groupName,
                            ),
                          ),
                        );
                      }
                    } else {
                      String fallbackGroupName = "Carpool to ${data['destination']}_${data['date']}_${data['time']}";
                      DocumentReference newGroupRef = await FirebaseFirestore.instance.collection('Groups').add({
                        'groupName': "Carpool to ${data['destination']}",
                        'participants': [data['email'], currentUserEmail], 
                        'lastMessage': "New member joined!",
                        'timestamp': FieldValue.serverTimestamp(),
                        'rideId': docId,
                      });

                      if (context.mounted) {
                        Navigator.pop(context); 
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => GroupMessagingPage(
                              groupId: newGroupRef.id,
                              groupName: fallbackGroupName,
                            ),
                          ),
                        );
                      }
                    }
                  } catch (e) {
                    if (context.mounted) {
                      Navigator.pop(context); // 关掉 Loading
                      print("Join error: $e");
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Error joining ride: $e"), backgroundColor: Colors.red),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: (isMyOwnRide || hasJoined || isFull) ? Colors.grey.shade200 : kThemeGreen, 
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), 
                  elevation: 0,
                ),
                child: Text(
                  isMyOwnRide ? "Your Carpool" :
                  hasJoined ? "Joined ✅" :
                  isFull ? "Ride Full" : "Join Ride",
                  style: TextStyle(
                    color: (isMyOwnRide || hasJoined || isFull) ? Colors.grey.shade500 : Colors.white, 
                    fontWeight: FontWeight.bold
                  )
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}