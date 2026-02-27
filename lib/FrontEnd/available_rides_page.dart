import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'match_in_advance_page.dart';
import 'home_page.dart'; // ✅ 获取 RideRequest 模型

const Color kThemeGreen = Color(0xFF2ECC71);

class AvailableRidesPage extends StatefulWidget {
  // ✅ 接收从主页传来的 currentUser (消除图 4 红线)
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
      
      // ✅ 1. 移除 Firebase 端严格的 .where 查询，拉取所有订单在本地过滤
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('scheduled_rides')
            // 去掉了 .where(...)，保证一定能拿到数据
            .snapshots(),
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

          // ✅ 2. 本地智能过滤引擎
          final validDocs = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            
            // 获取数据库里的目的地和当前用户搜索的目的地
            final String dbDest = (data['destination'] ?? '').toString().trim().toLowerCase();
            final String targetDest = widget.currentUser.destination.trim().toLowerCase();

            // 防呆设计：只要关键字互相包含，就算顺路！(比如 "APU" 和 "APU New Campus" 会被视为匹配)
            bool isDestMatch = dbDest.contains(targetDest) || targetDest.contains(dbDest);

            // 🚀 黑客松演示模式：强制返回 true，忽略角色和本人的限制，只要地点对得上就显示！
            return isDestMatch; 
          }).toList();

          // ✅ 3. 如果地点没匹配上，显示友好的提示
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
              final data = validDocs[index].data() as Map<String, dynamic>;
              return _buildRideCard(data, context);
            },
          );
        },
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: kThemeGreen,
        elevation: 4,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => MatchInAdvancePage(currentUser: widget.currentUser)),
          );
        },
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
    );
  }

  // ✅ 接收 Firebase 数据的卡片 UI
  Widget _buildRideCard(Map<String, dynamic> data, BuildContext context) {
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: kThemeGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                  child: Text(
                    "${data['seats']} Seats",
                    style: const TextStyle(color: kThemeGreen, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
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
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Successfully joined ${data['name']}'s ride! 🌍")),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: kThemeGreen, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), elevation: 0,
                ),
                child: const Text("Join Ride", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}