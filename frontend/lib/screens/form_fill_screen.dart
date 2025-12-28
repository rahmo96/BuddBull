import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:dio/dio.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';

class FormFillScreen extends StatefulWidget {
  final String? initialEmail;

  const FormFillScreen({super.key, this.initialEmail});

  @override
  State<FormFillScreen> createState() => _FormFillScreenState();
}

class _FormFillScreenState extends State<FormFillScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  final Dio _dio = ApiClient.instance;
  final AuthService _authService = AuthService();

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
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ),
              FormBuilder(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FormBuilderTextField(
                      name: 'firstName',
                      validator: FormBuilderValidators.compose([
                        FormBuilderValidators.required(
                          errorText: 'First name is required',
                        ),
                        FormBuilderValidators.minLength(
                          2,
                          errorText: 'Minimum 2 characters',
                        ),
                      ]),
                      decoration: const InputDecoration(
                        labelText: 'First Name',
                      ),
                    ),
                    const SizedBox(height: 15),
                    FormBuilderTextField(
                      name: 'lastName',
                      validator: FormBuilderValidators.compose([
                        FormBuilderValidators.required(
                          errorText: 'Last name is required',
                        ),
                        FormBuilderValidators.minLength(
                          2,
                          errorText: 'Minimum 2 characters',
                        ),
                      ]),
                      decoration: const InputDecoration(labelText: 'Last Name'),
                    ),
                    const SizedBox(height: 25),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      child: _isLoading
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Submit'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final isValid = _formKey.currentState?.saveAndValidate() ?? false;
    if (!isValid) return;

    final user = _authService.getCurrentUser();

    final email = user?.email;

    if (email == null || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Missing email. Please login again.')),
      );
      return;
    }

    final values = _formKey.currentState!.value;

    final payload = {
      "firebaseUid": user.uid,
      "email": email,
      "firstName": (values["firstName"] ?? "").toString().trim(),
      "lastName": (values["lastName"] ?? "").toString().trim(),
    };

    setState(() => _isLoading = true);

    try {
      await _dio.post('/users/profile', data: payload);

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile saved!')));

      // אם תרצה ניווט:
      // Navigator.pushReplacementNamed(context, '/home');
    } on DioException catch (e) {
      if (!mounted) return;

      final msg =
          e.response?.data?.toString() ??
          e.response?.statusMessage ??
          e.message ??
          'Request failed';

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
