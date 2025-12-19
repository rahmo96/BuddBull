import 'package:flutter/material.dart';
import '../services/auth_service.dart'; 

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true, 
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () async {
                // Step 1: Use try-catch to handle potential errors from Firebase
                try {
                  final user = await _authService.signUpWithEmail(
                    _emailController.text.trim(),
                    _passwordController.text.trim(),
                  );

                  if (user != null) {
                    // Step 2: Sign out immediately so the Wrapper stays on LoginScreen
                    await _authService.signOut();

                    if (mounted) {
                      // Step 3: Show success message to the user
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Account created! Please login.'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      
                      // Step 4: Go back to the previous screen (LoginScreen)
                      Navigator.pop(context);
                    }
                  }
                } catch (e) {
                  // Step 5: Catch the error thrown by AuthService and show it in a SnackBar
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(e.toString()),
                        backgroundColor: Colors.red,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              },
              child: const Text('Register'),
            ),
          ],
        ),
      ),
    );
  }
}