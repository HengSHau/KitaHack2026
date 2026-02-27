import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FeedbackService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Function to submit feedback to Firestore
  Future<bool> submitFeedback(String feedbackText) async {
    try {
      String? userEmail = _auth.currentUser?.email;

      if (userEmail != null && feedbackText.trim().isNotEmpty) {
        // Add a new document with an auto-generated ID
        await _firestore.collection('Feedback').add({
          'email': userEmail,
          'content': feedbackText.trim(),
          'timestamp': FieldValue.serverTimestamp(),
          'status': 'pending', // Useful for administrative tracking
        });
        return true;
      }
      return false;
    } catch (e) {
      print("Error submitting feedback: $e");
      return false;
    }
  }
}