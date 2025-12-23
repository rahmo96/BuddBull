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

  // Step 1: Add a loading state variable
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Image.asset(
              'assets/images/Ex_logo.png',
              height: 200,
              fit: BoxFit.cover,
            ),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 20),

            // Step 2: Show the spinner if _isLoading is true, otherwise show the button
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: () async {
                      // Step 3: Start loading
                      setState(() => _isLoading = true);

                      try {
                        await _authService.signInWithEmail(
                          _emailController.text.trim(),
                          _passwordController.text.trim(),
                        );
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(e.toString()),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      } finally {
                        // Step 4: Stop loading regardless of success or failure
                        if (mounted) {
                          setState(() => _isLoading = false);
                        }
                      }
                    },
                    child: const Text('Login'),
                  ),

            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const RegisterScreen()),
              ),
              child: const Text("New user? Register here"),
            ),
          ],
        ),
      ),
    );
  }
}
