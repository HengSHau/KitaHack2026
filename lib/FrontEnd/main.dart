import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // Ensure core is imported
import '../firebase_options.dart'; // 1. IMPORT your options file
import '../FrontEnd/login_page.dart';
import '../FrontEnd/home_page.dart';
import '../FrontEnd/register_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
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
      initialRoute: '/', 
        routes: {
          '/': (context) => const LoginPage(),      
          '/register': (context) => const RegisterPage(), 
          '/home': (context) => const HomePage(),    
        },
    );
  }
}
