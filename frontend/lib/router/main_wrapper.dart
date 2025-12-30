import 'package:buddbull/screens/auth/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../screens/layout/main_layout.dart';


class MainWrapper extends StatelessWidget {
  const MainWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // StreamBuilder listens to the "Auth State" in real-time
    return StreamBuilder<User?>(
      // Firebase sends a signal here every time someone logs in or out
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // If the snapshot has data, it means a user is already logged in
        if (snapshot.hasData) {
          return const MainLayout();
        }
        // If there is no data, it means no one is logged in, show Register
        return const LoginScreen();
      },
    );
  }
}