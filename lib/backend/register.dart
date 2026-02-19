import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> registerUser({
  required String username,
  required String email,
  required String password,
  required String personality,
}) async {
  try {
    
    // Create accout in  authentication
    UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );

    // Save data into fire store
    await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
      'username': username.trim(),
      'email': email.trim(),
      'personality': personality,
      'createdAt': DateTime.now(),
    });

    print("Register Successfully!");
  } on FirebaseAuthException catch (e) {
    //Checking that was what error occur in firebase
    print("Error: ${e.message}");
    rethrow; 
  }
}