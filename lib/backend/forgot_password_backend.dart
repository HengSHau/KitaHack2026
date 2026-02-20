import 'package:firebase_auth/firebase_auth.dart';
class ForgotPasswordBackend {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> sendResetEmail(String email) async {
    try {
      // This sends the automated email template from your Firebase console
      await _auth.sendPasswordResetEmail(email: email.trim());
      print("Reset email sent to $email");
    } on FirebaseAuthException catch (e) {
      // Common errors: 'user-not-found' or 'invalid-email'
      print("Firebase Auth Error: ${e.code}");
      rethrow; 
    } catch (e) {
      print("General Error: $e");
      rethrow;
    }
  }
}