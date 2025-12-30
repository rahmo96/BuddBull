import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../onboarding/introduction_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  final AuthService _authService = AuthService();
  final Dio _dio = ApiClient.instance;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Center(
                child: Image.asset(
                  'assets/images/Ex_logo.png',
                  height: 150,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 20),
              FormBuilder(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // --- Account Section ---
                    const Text(
                      "Account Details",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const Divider(),
                    FormBuilderTextField(
                      name: 'email',
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        hintText: 'example@mail.com',
                      ),
                      validator: FormBuilderValidators.compose([
                        FormBuilderValidators.required(),
                        FormBuilderValidators.email(),
                      ]),
                    ),
                    const SizedBox(height: 15),
                    FormBuilderTextField(
                      name: 'password',
                      decoration: const InputDecoration(labelText: 'Password'),
                      obscureText: true,
                      validator: FormBuilderValidators.compose([
                        FormBuilderValidators.required(),
                        FormBuilderValidators.minLength(8),
                      ]),
                    ),
                    const SizedBox(height: 30),

                    // --- Profile Section ---
                    const Text(
                      "Personal Information",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const Divider(),
                    FormBuilderTextField(
                      name: 'firstName',
                      decoration: const InputDecoration(
                        labelText: 'First Name',
                      ),
                      validator: FormBuilderValidators.compose([
                        FormBuilderValidators.required(
                          errorText: 'First name is required',
                        ),
                        FormBuilderValidators.minLength(2),
                      ]),
                    ),
                    const SizedBox(height: 15),
                    FormBuilderTextField(
                      name: 'lastName',
                      decoration: const InputDecoration(labelText: 'Last Name'),
                      validator: FormBuilderValidators.compose([
                        FormBuilderValidators.required(
                          errorText: 'Last name is required',
                        ),
                        FormBuilderValidators.minLength(2),
                      ]),
                    ),
                    const SizedBox(height: 15),
                    FormBuilderDropdown<String>(
                      name: 'gender',
                      decoration: const InputDecoration(labelText: 'Gender'),
                      validator: FormBuilderValidators.required(
                        errorText: 'Gender is required',
                      ),
                      items: const [
                        DropdownMenuItem(value: 'male', child: Text('Male')),
                        DropdownMenuItem(
                          value: 'female',
                          child: Text('Female'),
                        ),
                        DropdownMenuItem(value: 'other', child: Text('Other')),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
                onPressed: _isLoading ? null : _handleRegistration,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Register & Create Profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleRegistration() async {
    // 1. Validate all fields at once
    if (!(_formKey.currentState?.saveAndValidate() ?? false)) return;

    final values = _formKey.currentState!.value;
    setState(() => _isLoading = true);

    try {
      // 2. Register in Firebase Auth first
      User? user;
      try {
        user = await _authService.signUpWithEmail(
          values['email'],
          values['password'],
        );
      } catch (firebaseError) {
        // Firebase registration failed - show the error and stop
        _showError(firebaseError.toString() + " Firebase registration failed");
        return;
      }

      if (user == null) {
        _showError('Failed to create Firebase account. Please try again.');
        return;
      }

      // Store user.uid in a local variable for null safety
      final userUid = user.uid;

      // 3. Prepare payload for the backend API
      // Added the nested location structure required by your Mongoose schema
      final payload = {
        "firebaseUid": userUid,
        "personalInfo": {
          "firstName": (values["firstName"] ?? "").toString().trim(),
          "lastName": (values["lastName"] ?? "").toString().trim(),
          "email": values['email'],
          "gender": values["gender"],
        },
        "location": {
          "neighborhood": "Default", // You can add a field for this later
          "coordinates": {
            "type": "Point",
            "coordinates": [34.7818, 32.0853], // [Longitude, Latitude]
          },
        },
        "status": "active",
      };

      try {
        // 4. Send to Backend immediately
        await _dio.post('/users/register', data: payload);

        // 5. Navigate to introduction screen to complete profile
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account created! Now complete your profile.'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => IntroductionScreen(
                initialEmail: values['email'],
                initialUid: userUid,
                initialPersonalInfo: Map<String, dynamic>.from(
                  payload['personalInfo'] as Map,
                ),
              ),
            ),
          );
        }
      } on DioException catch (e) {
        // If backend fails, sign out from Firebase to clean up
        await _authService.signOut();

        // Improved error parsing to show exactly what the backend rejected
        final backendError = e.response?.data is Map
            ? e.response?.data['message']
            : e.response?.data;
        _showError("Backend Error: ${backendError ?? e.message}");
      }
    } catch (e) {
      // Handle Firebase Auth errors
      _showError("Registration Error: ${e.toString()}");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
