import 'package:flutter/material.dart';
import 'dart:async';
import 'match_success_page.dart';

const Color kThemeGreen = Color(0xFF2ECC71);

class MatchingPage extends StatefulWidget {
  final String destination;
  const MatchingPage({super.key, required this.destination});

  @override
  State<MatchingPage> createState() => _MatchingPageState();
}

class _MatchingPageState extends State<MatchingPage> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 3), () {
      if (mounted) {

        final List <Map<String,dynamic>> dummyAiResults=[
          {"name": "Lim", "personality": "Introverted", "email": "limluffy123@gmail.com"},
          {"name": "Tester", "personality": "Ambivert", "email": "test@gmail.com"},
          {"name": "Iris", "personality": "Ambivert", "email": "siweiseah@gmail.com"},
        ];
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder:(context)=>MatchSuccessPage(
              matchedUsers: dummyAiResults,
              // === 唯一修改的地方：补充这四个必要参数 ===
              origin: "APU", 
              destination: widget.destination,
              date: "12 Nov 2026", 
              time: "08:00 AM",
              // ======================================
            ),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 200,
                  height: 200,
                  child: CircularProgressIndicator(
                    strokeWidth: 8,
                    valueColor: AlwaysStoppedAnimation<Color>(kThemeGreen.withOpacity(0.2)),
                  ),
                ),
                const SizedBox(
                  width: 150,
                  height: 150,
                  child: CircularProgressIndicator(
                    strokeWidth: 4,
                    valueColor: AlwaysStoppedAnimation<Color>(kThemeGreen),
                  ),
                ),
                const Icon(Icons.auto_awesome, size: 50, color: kThemeGreen),
              ],
            ),
            const SizedBox(height: 40),
            Text(
              "Finding the best partner for your trip to\n${widget.destination}",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}