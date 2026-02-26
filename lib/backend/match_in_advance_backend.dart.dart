import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'notification_service.dart';

class AdvanceData{
  final FirebaseFirestore data = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;

  Future<void> createadvancedata({
    required DateTime datetime,
    required double hour,
    required double min,
  })async{
    try{
      User? user = auth.currentUser;
      if(user == null) throw Exception("User no Login");

      DateTime scheduletime = DateTime(
        datetime.year,
        datetime.month,
        datetime.day,
        hour.toInt(),
        min.toInt(),
      );
      DateTime tenMinsBefore = scheduletime.subtract(const Duration(minutes: 10));

      DocumentReference docRef = await data.collection("Advance Time").add({
        'UserID': user.uid,
        'Date&Time': scheduletime,
        'status': 'pending',
        'createAt': FieldValue.serverTimestamp(),
      });

      if (scheduletime.isAfter(DateTime.now())) {
        // 准点通知
        await NotificationService.scheduleAdvanceNotification(
          id: docRef.id.hashCode, // 使用文档 ID 的 hash 作为唯一标识
          title: "Time for your trip! 🚗",
          body: "Your booked trip is now starting, please depart on time.",
          scheduledTime: scheduletime,
        );

        // 提前10分钟通知
        if (tenMinsBefore.isAfter(DateTime.now())) {
          await NotificationService.scheduleAdvanceNotification(
            id: docRef.id.hashCode + 1, // 确保 ID 不同，否则会覆盖
            title: "Trip Reminder ⏳",
            body: "Your scheduled trip will begin in 10 minutes. Please be prepared.",
            scheduledTime: tenMinsBefore,
          );
        }
      }

      print("Booking has benn save!");
    }catch(e){
      print("Error save Booking: $e");
    }
  }
}