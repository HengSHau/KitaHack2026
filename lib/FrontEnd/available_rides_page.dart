import 'package:flutter/material.dart';
import 'match_in_advance_page.dart'; // 引入创建页面，用于悬浮按钮跳转

const Color kThemeGreen = Color(0xFF2ECC71);

// 1. 定义预约订单的数据模型
class ScheduledRide {
  final String id;
  final String driverName;
  final String date;
  final String time;
  final String start;
  final String destination;
  final int availableSeats;
  final String personality; 

  ScheduledRide({
    required this.id,
    required this.driverName,
    required this.date,
    required this.time,
    required this.start,
    required this.destination,
    required this.availableSeats,
    required this.personality,
  });
}

class AvailableRidesPage extends StatefulWidget {
  const AvailableRidesPage({super.key});

  @override
  State<AvailableRidesPage> createState() => _AvailableRidesPageState();
}

class _AvailableRidesPageState extends State<AvailableRidesPage> {
  // 2. 初始 Mock 数据：规范化性格，去掉了车型
  final List<ScheduledRide> _availableRides = [
    ScheduledRide(
      id: "r1",
      driverName: "Sarah", 
      date: "2026-03-01",
      time: "08:30 AM",
      start: "Bukit Jalil LRT",
      destination: "APU New Campus",
      availableSeats: 2,
      personality: "Extroverted", 
    ),
    ScheduledRide(
      id: "r2",
      driverName: "Alex", 
      date: "2026-03-01",
      time: "09:00 AM",
      start: "Parkhill Residence",
      destination: "APU New Campus",
      availableSeats: 1,
      personality: "Introverted", 
    ),
    ScheduledRide(
      id: "r3",
      driverName: "David", 
      date: "2026-03-02",
      time: "10:15 AM",
      start: "Pavilion Bukit Jalil",
      destination: "APU New Campus",
      availableSeats: 3,
      personality: "Ambiverted", 
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () {
            Navigator.pop(context);
          }
        ),
        title: const Text(
          "Available Carpools",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _availableRides.length,
        itemBuilder: (context, index) {
          final ride = _availableRides[index];
          // 这里调用下面定义的卡片构建函数
          return _buildRideCard(ride, context);
        },
      ),
      // ✅ 右下角 Fixed 的悬浮创建按钮
      floatingActionButton: FloatingActionButton(
        backgroundColor: kThemeGreen,
        elevation: 4,
        onPressed: () async {
          // 跳转到创建页面，并等待它传回新建的订单数据
          final newRide = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const MatchInAdvancePage()),
          );

          // 如果成功传回了数据，把它加到列表最上面
          if (newRide != null && newRide is ScheduledRide) {
            setState(() {
              _availableRides.insert(0, newRide); 
            });
          }
        },
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
    );
  }

  // ✅ 就是这个函数之前被你不小心删掉了！现在补回来了。
  Widget _buildRideCard(ScheduledRide ride, BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 顶部：司机信息和座位数
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: kThemeGreen.withOpacity(0.15),
                      child: const Icon(Icons.person, color: kThemeGreen),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(ride.driverName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        // 显示 Personality
                        Text("Personality: ${ride.personality}", style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: kThemeGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "${ride.availableSeats} Seats Left",
                    style: const TextStyle(color: kThemeGreen, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
            
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12.0),
              child: Divider(),
            ),

            // 中间：时间和路线
            Row(
              children: [
                const Icon(Icons.calendar_month, size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                Text("${ride.date} • ${ride.time}", style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
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
                      Text(ride.start, style: const TextStyle(fontSize: 14)),
                      const SizedBox(height: 14),
                      Text(ride.destination, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 底部：加入按钮
            SizedBox(
              width: double.infinity,
              height: 45,
              child: ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      title: const Text("Confirm Booking"),
                      content: Text("Do you want to join ${ride.driverName}'s ride to ${ride.destination}?"),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: kThemeGreen),
                          onPressed: () {
                            Navigator.pop(context); 
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Successfully joined ${ride.driverName}'s ride! 🌍")),
                            );
                          },
                          child: const Text("Join Ride", style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: kThemeGreen,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
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