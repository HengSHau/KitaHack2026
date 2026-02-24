import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EditProfileService {
  final FirebaseFirestore _firestore=FirebaseFirestore.instance;
  final FirebaseAuth _auth=FirebaseAuth.instance;

  Future <bool> updateProfile({
    required String newUsername,
    required String newPhone,
  }) async {
    try{
      String?email=_auth.currentUser?.email;

      if(email !=null){
        await _firestore.collection('users').doc(email).update({
          'username':newUsername,
          'phone':newPhone,
          'lastUpdated':FieldValue.serverTimestamp(),
        });
      return true;
      }
      return false;
      
    }catch(e){
      print("Error updating profile: $e");
      return false;
    }
  }

  Future<Map<String,dynamic>?>getUserData()async{
    try{
      String? email=_auth.currentUser?.email;
      if(email !=null){
        DocumentSnapshot doc=await _firestore.collection('users').doc(email).get();
        return doc.data() as Map<String,dynamic>?;
      }
      return null;
    }catch(e){
      print("Error fetching user data:$e");
      return null;
    }
  }
}

