import 'package:flutter/material.dart';
import 'FrontEnd/login_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Auth UI Demo', // Updated title from kingsen
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green), // Merged green theme
        scaffoldBackgroundColor: Colors.white,
        useMaterial3: true,
      ),
      // Setting LoginPage as the entry point for your online learning platform
      home: const LoginPage(), 
    );
  }
}

// You can keep the MyHomePage classes below if you still need the counter logic for testing, 
// otherwise, you can safely delete them since the app now starts at LoginPage().