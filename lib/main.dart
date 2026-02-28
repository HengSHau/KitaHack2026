import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'FrontEnd/login_page.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../backend/notification_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await NotificationService.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {

    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'GreenNode',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        scaffoldBackgroundColor: Colors.white,
        useMaterial3: true,
      ),
      // Setting LoginPage as the entry point
      home: const LoginPage(), 

      initialRoute: '/',
      routes: {
        '/login': (context) => const LoginPage(),
      },
    );
  }
}
