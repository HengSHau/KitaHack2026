import 'package:flutter/material.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
    print("--- Notification channel initialization is complete. ---");
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

  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? groupKey,
    Map<String, String>? payload,
  }) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: id,
        channelKey: 'carpool_notifications',
        title: title,
        body: body,
        groupKey: groupKey,
        payload: payload,
        notificationLayout: NotificationLayout.Default,
      ),
    );

    AwesomeNotifications().setListeners(
      onActionReceivedMethod: (ReceivedAction receivedAction) async {
        final payload = receivedAction.payload;
        if (payload != null && payload['senderEmail'] != null) {
          String senderEmail = payload['senderEmail']!;
          String myEmail = FirebaseAuth.instance.currentUser?.email ?? "";

          // 去 Firestore 把该发件人发给我的所有未读消息标为已读
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
          await AwesomeNotifications().dismiss(receivedAction.id!);
          print("The message from $senderEmail has been marked as read.");
        }
      },
    );
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
  // 单例模式改为 AppNotificationListener
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

            int notificationId = (data['sender'] ?? "default").hashCode;

            NotificationService.showNotification(
              id: notificationId, 
              title: '来自 $senderName 的新消息',
              body: text,
              payload: {"senderEmail": data['sender'] ?? ""},
              groupKey: data['sender'], 
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