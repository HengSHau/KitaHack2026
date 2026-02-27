import 'package:flutter/material.dart';
import 'dart:async';
import 'match_success_page.dart';
import '../backend/gemini_service.dart';
import 'home_page.dart';

const Color kThemeGreen = Color(0xFF2ECC71);

class MatchingPage extends StatefulWidget {
  final RideRequest currentUser;
  const MatchingPage({super.key, required this.currentUser});

  @override
  State<MatchingPage> createState() => _MatchingPageState();
}

class _MatchingPageState extends State<MatchingPage> {
  final Set<String> _rejectedIds = {};

  // Fake database
  final List<RideRequest> databasePool = [
    RideRequest(id: "p1", name: "Ali", role: "passenger", start: "LRT Station", destination: "APU New Campus", seats: 1, personality: "Quiet"),
    RideRequest(id: "d1", name: "Sarah", role: "driver", start: "Bukit Jalil", destination: "APU New Campus", seats: 3, personality: "Talkative"),
    RideRequest(id: "d2", name: "Alex", role: "driver", start: "Bukit Jalil", destination: "APU New Campus", seats: 1, personality: "Introverted"),
  ];

  @override
  void initState() {
    super.initState();
    findBestMatch(widget.currentUser, databasePool);
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
              "Finding the best partner for your trip to\n${widget.currentUser.destination}",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
            const SizedBox(height: 60),
            TextButton(
                onPressed: () {
                  Navigator.pop(context); 
                  print("User cancelled the search.");
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                    side: BorderSide(color: Colors.redAccent.shade200, width: 1.5),
                  ),
                ),
                child: Text(
                  "Cancel Search", 
                  style: TextStyle(color: Colors.redAccent.shade200, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> findBestMatch(RideRequest currentUser, List<RideRequest> databasePool) async {
    final aiService = GeminiMatchService();
    RideRequest? bestMatch;
    bool needsPersonalityConsent = false;

    for (var candidate in databasePool) {
      if (_rejectedIds.contains(candidate.id)) {
        continue; 
      }

      if (currentUser.role == candidate.role) continue;
      if (currentUser.role == 'driver' && currentUser.seats < candidate.seats) continue;
      if (currentUser.role == 'passenger' && candidate.seats < currentUser.seats) continue;

      String driverStart = currentUser.role == 'driver' ? currentUser.start : candidate.start;
      String driverEnd = currentUser.role == 'driver' ? currentUser.destination : candidate.destination;
      String passStart = currentUser.role == 'passenger' ? currentUser.start : candidate.start;
      String passEnd = currentUser.role == 'passenger' ? currentUser.destination : candidate.destination;

      bool isRouteMatch = await aiService.checkMatch(
        driverStart: driverStart,
        driverEnd: driverEnd,
        passengerStart: passStart,
        passengerEnd: passEnd,
      );

      if (isRouteMatch) {
        if (bestMatch == null) {
          bestMatch = candidate;
          needsPersonalityConsent = (currentUser.personality != candidate.personality);
        } else {
          if (currentUser.personality == candidate.personality && 
              currentUser.personality != bestMatch.personality) {
            bestMatch = candidate;
            needsPersonalityConsent = false; 
          }
        }
      }
    }

    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    if (bestMatch != null) {
      if (needsPersonalityConsent) {
        _showPersonalityDialog(bestMatch);
      } else {
        _goToSuccessPage(bestMatch);
      }
    } else {
      print("No matches found at this time.");
      Navigator.pop(context);
    }
  }

  void _showPersonalityDialog(RideRequest match) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text("Route Matched!"),
          content: Text(
            "We found a partner going your way! However, their vibe is '${match.personality}' while yours is '${widget.currentUser.personality}'.\n\nAre you okay with riding together?"
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _rejectedIds.add(match.id);
                });
                print("User rejected the match due to personality.");
                findBestMatch(widget.currentUser, databasePool);
              },
              child: const Text("No, keep searching", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2ECC71)),
              onPressed: () {
                Navigator.pop(context);
                _goToSuccessPage(match);
              },
              child: const Text("Yes, I'm okay with it", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _goToSuccessPage(RideRequest match) {
    Navigator.pushReplacement(
      context, 
      MaterialPageRoute(builder: (context) => const MatchSuccessPage())
    );
  }
}