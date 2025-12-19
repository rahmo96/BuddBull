import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'register_screen.dart'; // To navigate to signup

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email')),
            TextField(controller: _passwordController, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                // Here we call the "Sign In" brain function we just created
                await _authService.signInWithEmail(_emailController.text, _passwordController.text);
              },
              child: const Text('Login'),
            ),
            TextButton(
              onPressed: () {
                // Manual move to Register if they don't have an account
                Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterScreen()));
              },
              child: const Text("New user? Register here"),
            )
          ],
        ),
      ),
    );
  }
}