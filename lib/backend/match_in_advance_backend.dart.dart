import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

      await data.collection("Advance Time").add({
        'UserID': user.uid,
        'Date&Time': scheduletime,
        'status': 'panding',
        'createAt': FieldValue.serverTimestamp(),
      });

      print("Booking has benn save!");
    }catch(e){
      print("Error save Booking: $e");
    }
  }
}