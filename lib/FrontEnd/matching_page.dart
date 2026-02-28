import 'package:flutter/material.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'match_success_page.dart';
import '../backend/gemini_service.dart';
import 'home_page.dart';
import 'package:kitahack2026/backend/notification_service.dart';

const Color kThemeGreen = Color(0xFF2ECC71);

class MatchingPage extends StatefulWidget {
  final RideRequest currentUser;
  const MatchingPage({super.key, required this.currentUser});

  @override
  State<MatchingPage> createState() => _MatchingPageState();
}

class _MatchingPageState extends State<MatchingPage> {
  final Set<String> _rejectedEmails = {};

  List<RideRequest> databasePool = [];

  @override
  void initState() {
    super.initState();
    _fetchRealDataAndMatch();
  }

  Future<void> _fetchRealDataAndMatch() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('ride_requests').get();

      List<RideRequest> fetchedRequests = [];

      for (var doc in snapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;

        // Filter self requests
        if (data['email'] == widget.currentUser.email) continue;

        double otherLat = (data['dest_lat'] ?? 0.0).toDouble();
        double otherLng = (data['dest_lng'] ?? 0.0).toDouble();    

        fetchedRequests.add(
          RideRequest(
            email: data['email'] ?? "",
            name: data['name'] ?? "Unknown",
            role: data['role'] ?? "passenger",
            start: data['start'] ?? "",
            destination: data['destination'] ?? "",
            seats: data['seats'] ?? 1,
            personality: data['personality'] ?? "Introverted",
            destLat: otherLat, 
            destLng: otherLng,
          )
        );
      }

      if (mounted) {
        setState(() {
          databasePool = fetchedRequests;
        });
      }

      findBestMatch(widget.currentUser, databasePool);

    } catch (e) {
      print("Error fetching ride requests from Firebase: $e");
      if (mounted) {
        _showNoMatchFoundDialog();
      }
    }
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

  Future<void> findBestMatch(RideRequest currentUser, List<RideRequest> pool) async {
    if (pool.isEmpty) {
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) _showNoMatchFoundDialog();
      return;
    }

    final aiService = GeminiMatchService();
    RideRequest? bestMatch;
    bool needsPersonalityConsent = false;

    for (var candidate in pool) {
      if (_rejectedEmails.contains(candidate.email)) continue; 
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

    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;

    if (bestMatch != null) {
      if (needsPersonalityConsent) {
        _showPersonalityDialog(bestMatch);
      } else {
        _goToSuccessPage(bestMatch);
      }
    } else {
      _showNoMatchFoundDialog();
    }
  }

  void _showNoMatchFoundDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text("No Match Found 😔"),
          content: const Text("Sorry, we couldn't find a suitable partner for your route at this time. Please try again later or adjust your request."),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: kThemeGreen),
              onPressed: () {
                Navigator.pop(context); 
                Navigator.pop(context); 
              },
              child: const Text("OK", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
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
                setState(() => _rejectedEmails.add(match.email));
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
    DateTime now = DateTime.now();

    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    String realDate = "${now.day} ${months[now.month-1]} ${now.year}"; 

    int h = now.hour;
    int m = now.minute;

    String period = h >= 12 ? "PM" : "AM";
    if (h == 0) h = 12; 
    if (h > 12) h -= 12;

    String minuteStr = m < 10 ? "0$m" : "$m";
    String realTime = "$h:$minuteStr $period";

    final List<Map<String, dynamic>> matchedUsers = [
      {
        "name": match.name, 
        "personality": match.personality, 
        "email": match.email
      },
    ];

    Navigator.pushReplacement(
      context, 
      MaterialPageRoute(
        builder: (context) => MatchSuccessPage(
          matchedUsers: matchedUsers,
          origin: "APU", 
          destination: widget.currentUser.destination,
          date: realDate,
          time: realTime,
        )
      )
    );

    NotificationService.showNotification(
      id: 999,
      title: "Match Successful！🚗",
      body: "The system has matched you with ${match.name}. Click to view details.",
      senderName: "System",
      senderEmail: "system@kitahack.com",
      type: "match",
      payload: {
        "type": "match",
        "matchName": match.name,
        "matchPersonality": match.personality,
        "matchEmail": match.email,
        "origin": "APU", 
        "destination": widget.currentUser.destination,
        "date": realDate,
        "time": realTime,
      },
    );
  }
}