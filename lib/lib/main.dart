import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'login_screen.dart';
import 'map_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
      debugShowCheckedModeBanner: false,

      // ✅ ADD ROUTES (for navigation)
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const MapScreen(),
      },

      // ✅ REAL-TIME AUTH CHECK
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {

          // 🔄 Loading state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          // 🔐 If user logged in → MapScreen
          if (snapshot.hasData) {
            return const MapScreen();
          }

          // 🔓 If not logged in → LoginScreen
          return const LoginScreen();
        },
      ),
    );
  }
}
