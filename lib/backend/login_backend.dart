import 'package:firebase_auth/firebase_auth.dart';

class LoginBackend {
  // Create an instance of Firebase Auth
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Handles user login using email and password
  Future<User?> signInWithEmail(String email, String password) async {
    try {
      // Attempt to sign in
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Return the user object if successful
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      // Handle specific Firebase errors (e.g., wrong password, user not found)
      print("Firebase Login Error: ${e.code} - ${e.message}");
      return null;
    } catch (e) {
      // Handle any other errors
      print("Unexpected Login Error: $e");
      return null;
    }
  }

  /// Handles signing out
  Future<void> signOut() async {
    await _auth.signOut();
  }
}