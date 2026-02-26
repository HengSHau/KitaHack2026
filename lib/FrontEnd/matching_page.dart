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
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MatchSuccessPage()),
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