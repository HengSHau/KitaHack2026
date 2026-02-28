import 'package:flutter/material.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kitahack2026/main.dart';
import 'package:kitahack2026/FrontEnd/chat_page.dart';
import 'package:kitahack2026/FrontEnd/match_success_page.dart';

class NotificationService {
  static Future<void> initialize() async {
    await AwesomeNotifications().initialize(
      null,
      [
        NotificationChannel(
          channelKey: 'carpool_notifications',
          channelName: 'Schedule and Message Notice',
          channelDescription: 'Important real-time notifications for ride-sharing systems',
          defaultColor: const Color(0xFF00FF00),
          ledColor: Colors.white,
          importance: NotificationImportance.Max,
          channelShowBadge: true,
          playSound: true,
        )
      ],
      debug: true,
    );

    AwesomeNotifications().setListeners(
      onActionReceivedMethod: onActionReceivedMethod,
    );

    print("--- Notification initialization complete ---");
  }

  static Future<void> onActionReceivedMethod(ReceivedAction receivedAction) async {
    final payload = receivedAction.payload;
    if (payload == null) return;

    if (payload['type'] == 'match') {
    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (context) => MatchSuccessPage(
          matchedUsers: [
            {
              "name": payload['matchName'] ?? "Partner",
              "personality": payload['matchPersonality'] ?? "Unknown",
              "email": payload['matchEmail'] ?? "",
            }
          ],
          origin: payload['origin'] ?? "Current Location",
          destination: payload['destination'] ?? "Destination",
          date: payload['date'] ?? "",
          time: payload['time'] ?? "",
        ),
      ),
    );
    return;
  }

    if (payload['userEmail'] != null) {
      String name = payload['userName'] ?? "User";
      String email = payload['userEmail']!;
      String myEmail = FirebaseAuth.instance.currentUser?.email ?? "";

      print("Jump to Chat Page with $email");

      _markAsRead(email, myEmail);

      await AwesomeNotifications().dismiss(receivedAction.id!);

      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (context) => ChatMessagingPage(
            userName: name,
            userEmail: email,
          ),
        ),
      );
    }
  }

  static Future<void> _markAsRead(String senderEmail, String myEmail) async {
    var batch = FirebaseFirestore.instance.batch();
    var snapshots = await FirebaseFirestore.instance
        .collection('Chat')
        .where('sender', isEqualTo: senderEmail)
        .where('receiver', isEqualTo: myEmail)
        .where('isRead', isEqualTo: false)
        .get();

    for (var doc in snapshots.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    required String senderName,
    required String senderEmail,
    String? groupKey,
    String? type,
    Map<String, String>? payload,
  }) async {

    Map<String, String> finalPayload = {
      "type": type ?? "chat",
      "userName": senderName,
      "userEmail": senderEmail,
    };
    if (payload != null) {
      finalPayload.addAll(payload);
     }

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: id,
        channelKey: 'carpool_notifications',
        title: title,
        body: body,
        groupKey: groupKey,
        payload: finalPayload,
        notificationLayout: NotificationLayout.Default,
      ),
    );
  }

  static Future<bool> requestNotificationPermission(BuildContext context) async {
    bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) {
      if (!context.mounted) return false;
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Turn on notifications 🚗'),
          content: const Text('To ensure you receive passenger messages and order notifications, please allow notifications.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Next Time'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await AwesomeNotifications().requestPermissionToSendNotifications();
              },
              child: const Text('Allow'),
            ),
          ],
        ),
      );
    }
    return await AwesomeNotifications().isNotificationAllowed();
  }


  static Future<void> scheduleAdvanceNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    }) async {
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: id,
          channelKey: 'carpool_notifications',
          title: title,
          body: body,
          category: NotificationCategory.Alarm,
          notificationLayout: NotificationLayout.Default,
          wakeUpScreen: true, 
        ),
        schedule: NotificationCalendar.fromDate(date: scheduledTime),
      );
    }
}

class AppNotificationListener {
  static final AppNotificationListener _instance = AppNotificationListener._internal();
  factory AppNotificationListener() => _instance;
  AppNotificationListener._internal();

  StreamSubscription<QuerySnapshot>? _subscription;
  String? _lastMessageId; 

  void startListening() {
    final String? myEmail = FirebaseAuth.instance.currentUser?.email;
    
    if (myEmail == null) return;
    if (_subscription != null) return;

    print("--- Enable global message listening, with the following goal: $myEmail ---");

    _subscription = FirebaseFirestore.instance
        .collection('Chat')
        .where('participants', arrayContains: myEmail)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data() as Map<String, dynamic>;
          final String msgId = change.doc.id;
          final String receiver = data['receiver'] ?? "";
          final String senderName = data['senderName'] ?? "New Message";
          final String text = data['text'] ?? "";

          if (receiver == myEmail && msgId != _lastMessageId) {
            _lastMessageId = msgId;

            String senderEmail = data['sender'] ?? "";
            String senderName = data['senderName'] ?? "New Message";

            NotificationService.showNotification(
              id: senderEmail.hashCode, 
              title: 'Message from $senderName',
              body: text,
              senderName: senderName,
              senderEmail: senderEmail,
              groupKey: senderEmail, 
            );
          }
        }
      }
    });
  }

  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
  }
}