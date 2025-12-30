import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../../router/main_wrapper.dart';

class IntroductionScreen extends StatefulWidget {
  const IntroductionScreen({
    super.key,
    required this.initialEmail,
    required this.initialUid,
    required this.initialPersonalInfo,
  });
  final String? initialEmail;
  final String? initialUid;
  final Map<String, dynamic>? initialPersonalInfo;

  @override
  State<IntroductionScreen> createState() => _IntroductionScreenState();
}

class _IntroductionScreenState extends State<IntroductionScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  final Dio _dio = ApiClient.instance;
  bool _isLoading = false;
  DateTime? _selectedBirthday;

  // List of popular sports for selection
  final List<String> _sportsOptions = [
    'Football',
    'Basketball',
    'Tennis',
    'Soccer',
    'Baseball',
    'Volleyball',
    'Swimming',
    'Running',
    'Cycling',
    'Gym/Fitness',
    'Yoga',
    'Martial Arts',
    'Golf',
    'Hiking',
    'Rock Climbing',
    'Surfing',
    'Skateboarding',
    'Other',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Tell Us About Yourself',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: FormBuilder(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Section
                const Text(
                  "Complete Your Profile",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                const Text(
                  "Help us get to know you better",
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),

                // Birthday Section
                const Text(
                  "Birthday",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 10),
                FormBuilderField<DateTime>(
                  name: 'birthday',
                  validator: FormBuilderValidators.compose([
                    FormBuilderValidators.required(
                      errorText: 'Birthday is required',
                    ),
                  ]),
                  builder: (FormFieldState<DateTime> field) {
                    return InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Select your birthday',
                        hintText: 'Tap to select date',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.calendar_today),
                        errorText: field.errorText,
                      ),
                      child: InkWell(
                        onTap: () async {
                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate:
                                _selectedBirthday ??
                                DateTime.now().subtract(
                                  const Duration(days: 365 * 18),
                                ),
                            firstDate: DateTime(1950),
                            lastDate: DateTime.now(),
                            helpText: 'Select your birthday',
                          );
                          if (picked != null && picked != _selectedBirthday) {
                            setState(() {
                              _selectedBirthday = picked;
                            });
                            field.didChange(picked);
                          }
                        },
                        child: Text(
                          _selectedBirthday != null
                              ? DateFormat(
                                  'yyyy-MM-dd',
                                ).format(_selectedBirthday!)
                              : 'Tap to select date',
                          style: TextStyle(
                            color: _selectedBirthday != null
                                ? Colors.black87
                                : Colors.grey[600],
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 25),

                // Sports Interests Section
                const Text(
                  "Sports Interests",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Select all that apply",
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 15),
                FormBuilderCheckboxGroup<String>(
                  name: 'sportsInterests',
                  decoration: const InputDecoration(border: InputBorder.none),
                  options: _sportsOptions
                      .map(
                        (sport) => FormBuilderFieldOption(
                          value: sport,
                          child: Text(sport),
                        ),
                      )
                      .toList(),
                  validator: FormBuilderValidators.compose([
                    FormBuilderValidators.required(
                      errorText: 'Please select at least one sport',
                    ),
                    FormBuilderValidators.minLength(
                      1,
                      errorText: 'Please select at least one sport',
                    ),
                  ]),
                  wrapSpacing: 8,
                  wrapRunSpacing: 8,
                ),
                const SizedBox(height: 25),

                // About Yourself Section
                const Text(
                  "About Yourself",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 10),
                FormBuilderTextField(
                  name: 'about',
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Tell us about yourself',
                    hintText:
                        'Share your interests, hobbies, or what you\'re looking for...',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  validator: FormBuilderValidators.compose([
                    FormBuilderValidators.required(
                      errorText: 'Please tell us about yourself',
                    ),
                    FormBuilderValidators.minLength(
                      10,
                      errorText: 'Please write at least 10 characters',
                    ),
                    FormBuilderValidators.maxLength(
                      500,
                      errorText: 'Maximum 500 characters',
                    ),
                  ]),
                ),
                const SizedBox(height: 40),

                // Submit Button
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                        onPressed: _handleSubmit,
                        child: const Text(
                          'Complete Profile',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (!(_formKey.currentState?.saveAndValidate() ?? false)) return;

    final values = _formKey.currentState!.value;
    setState(() => _isLoading = true);

    try {
      // Get current user
      final authService = AuthService();
      final user = authService.getCurrentUser();
      if (user == null) {
        throw 'User not authenticated';
      }

      // Format birthday
      final birthday = values['birthday'] as DateTime?;
      final birthdayString = birthday != null
          ? DateFormat('yyyy-MM-dd').format(birthday)
          : null;

      // Get initial personal info from registration
      final firstName =
          widget.initialPersonalInfo?['firstName'] as String? ?? '';
      final lastName = widget.initialPersonalInfo?['lastName'] as String? ?? '';
      final email = widget.initialEmail ?? '';
      final gender = widget.initialPersonalInfo?['gender'] as String?;

      // Prepare payload for the backend API
      final payload = {
        "firebaseUid": widget.initialUid ?? user.uid,
        "personalInfo": {
          "firstName": firstName,
          "lastName": lastName,
          "email": email,
          if (gender != null) "gender": gender,
          "birthday": birthdayString,
          "sportsInterests": values['sportsInterests'] as List<String>? ?? [],
          "about": values['about'] as String? ?? '',
        },
      };

      // Send to Backend
      await _dio.put('/users/profile', data: payload);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile completed successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate to main app
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainWrapper()),
        );
      }
    } on DioException catch (e) {
      final backendError = e.response?.data is Map
          ? e.response?.data['message']
          : e.response?.data;
      _showError("Error: ${backendError ?? e.message}");
    } catch (e) {
      _showError(e.toString());
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
