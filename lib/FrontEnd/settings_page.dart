import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'edit_profile_page.dart';
import 'feedback_page.dart';
import 'help_center_page.dart';

const Color kThemeGreen = Color(0xFF00B14F); 

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Settings', 
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 26, color: Colors.black)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            _buildProfileHeader(),
            const SizedBox(height: 24),

            Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 5))
                ],
              ),
              child: Column(
                children: [
                  _buildGreenButton(Icons.person_outline, 'Edit Profile', () {
                    Navigator.push(
                      context, 
                      MaterialPageRoute(builder:(context) => const EditProfilePage()),
                    );
                  }),
                  const Divider(height: 32, thickness: 0.5),
                  _buildGreenButton(Icons.feedback_outlined, 'Feedback', () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder:(context) => FeedbackPage()),
                    );
                  }),
                  const Divider(height: 32, thickness: 0.5),
                  _buildGreenButton(Icons.help_outline, 'Help Center', () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => HelpCenterPage()),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    final String? myEmail=FirebaseAuth.instance.currentUser?.email;
    return StreamBuilder<QuerySnapshot>(
      stream:FirebaseFirestore.instance.collection('users').where('email',isEqualTo: myEmail).snapshots(),
      builder: (BuildContext context,snapshot){
        String displayName="Loading...";

        if(snapshot.hasData&&snapshot.data!.docs.isNotEmpty){
          final userData=snapshot.data!.docs.first.data() as Map<String,dynamic>;
          displayName=userData['username']??"User";
        }else if(snapshot.hasError){
          displayName="Error loading";
        }

        return Row(
          children:[
            const CircleAvatar(
              radius:35,
              backgroundColor:kThemeGreen,
              child:Icon(Icons.person,size:40,color:Colors.white),
            ),
            const SizedBox(width:15),
            Text(
              displayName,
              style:const TextStyle(
                fontSize:24,
                fontWeight:FontWeight.bold,
                color:Colors.black87,
              )
            )
          ],
        );
      },
    );
  }

  Widget _buildGreenButton(IconData icon, String title, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: kThemeGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: kThemeGreen, size: 22),
          ),
          const SizedBox(width: 16),
          Text(title, 
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black87)),
          const Spacer(),
          const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        ],
      ),
    );
  }
}