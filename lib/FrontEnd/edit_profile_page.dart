import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // NECESSARY
import 'package:firebase_auth/firebase_auth.dart';    // NECESSARY

const Color kThemeGreen = Color(0xFF2ECC71); 

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  // NECESSARY: Removed hardcoded text to allow loading from database
  final TextEditingController usernameController = TextEditingController();
  String? originalUsername;
  String? selectedPersonality;
  bool _isLoading = false; // NECESSARY for async UX

  final List<String> personalityOptions = ["Introverted", "Extroverted", "Ambivert"];

  // NECESSARY: Added initState to load real data
  @override
  void initState() {
    super.initState();
    _loadCurrentUserData();
  }

  // NECESSARY: Fetch logic
  Future<void> _loadCurrentUserData() async {
    String? email = FirebaseAuth.instance.currentUser?.email;
    if (email != null) {
      DocumentSnapshot doc = await FirebaseFirestore.instance.collection('users').doc(email).get();
      if (doc.exists && mounted) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          String currentName=data['username']??"";
          usernameController.text = currentName;
          originalUsername=currentName;
          selectedPersonality = data['personality'] ?? "Introverted";
        });
      }
    }
  }

  // NECESSARY: Save logic
  Future<void> _saveProfile() async {
    String enteredName=usernameController.text.trim();

    String finalName=enteredName;
    if(finalName.isEmpty){
      if(originalUsername!=null&&originalUsername!.isNotEmpty){
        finalName=originalUsername!;
        usernameController.text=finalName;
      }else{
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content:Text("Username cannot be empty")),
        );
        return;
      }
    }

    if(selectedPersonality==null||selectedPersonality!.isEmpty){
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select a personality type."),
          backgroundColor: Colors.orange,
        )
      );
      return;
    }

    setState(() => _isLoading = true);

    try{
      final String? email=FirebaseAuth.instance.currentUser?.email;

      if(email!=null){
        var querySnapshot=await FirebaseFirestore.instance  
          .collection('users')
          .where('email',isEqualTo: email)
          .get();
      

        if(querySnapshot.docs.isNotEmpty){
          await querySnapshot.docs.first.reference.update({
            'username':usernameController.text.trim(),
            'personality':selectedPersonality,
          });


          if(!mounted)return;

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content:Text("Profile updated!"),backgroundColor:kThemeGreen),
          );
          Navigator.pop(context);
        }
      } 
    }catch(e){
      if(mounted){
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );   
      };
    }finally{
      if(mounted){
        setState(()=> _isLoading=false);
      }
    }

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Edit Profile', 
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      // NECESSARY: Wrap body to show loading spinner
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: kThemeGreen))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: kThemeGreen,
                      child: const Icon(Icons.person, size: 60, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 30),

                  const Text(
                    "Username",
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: usernameController,
                    decoration: InputDecoration(
                      hintText: "Enter your username",
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: kThemeGreen, width: 2),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    "Personality",
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: selectedPersonality,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    items: personalityOptions.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        selectedPersonality = newValue;
                      });
                    },
                  ),

                  const SizedBox(height: 40),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _saveProfile, // NECESSARY: Linked to Firestore
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kThemeGreen,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        "Save Changes",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}