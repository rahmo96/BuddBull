import 'package:flutter/material.dart';
import '../services/auth_service.dart'; 
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // Controllers to capture user input from the text fields
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  // Instance of our AuthService
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Email Input Field
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 15),
            // Password Input Field
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true, // Hides the password
            ),
            const SizedBox(height: 30),
            // Sign Up Button
            ElevatedButton(
              onPressed: () async {
                // Call the service and wait for the result
                final user = await _authService.signUpWithEmail(
                  _emailController.text,
                  _passwordController.text,
                );

                if (user != null) {
                  print("Success! User created: ${user.uid}");
                } else {
                  print("Registration failed.");
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