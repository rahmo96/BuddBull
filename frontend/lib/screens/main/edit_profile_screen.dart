import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';
import '../../services/auth_service.dart';
import '../../services/profile_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  final ProfileService _profileService = ProfileService();
  final AuthService _authService = AuthService();

  bool _isLoading = true;
  bool _isSaving = false;
  String? _loadError;

  bool _isLocationLoading = false;
  Position? _currentPosition;

  DateTime? _selectedBirthday;

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
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = _authService.getCurrentUser();
    if (user == null) {
      setState(() {
        _loadError = 'Not signed in';
        _isLoading = false;
      });
      return;
    }

    try {
      final profile = await _profileService.getProfile(user.uid);
      final personalInfo = profile['personalInfo'] as Map<String, dynamic>?;
      final location = profile['location'] as Map<String, dynamic>?;

      setState(() {
        _cachedProfile = profile;
        _selectedBirthday = _parseDate(personalInfo?['dateOfBirth']);
        _cachedNeighborhood = location?['neighborhood'] as String?;
        _isLoading = false;
      });
    } on DioException catch (e) {
      final msg = e.response?.statusCode == 404
          ? 'Profile not found. Complete onboarding first.'
          : e.response?.data is Map
              ? e.response?.data['message']
              : e.message;
      setState(() {
        _loadError = msg?.toString() ?? 'Failed to load profile';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _loadError = e.toString();
        _isLoading = false;
      });
    }
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLocationLoading = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw 'Location services are disabled. Please enable GPS.';
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'Location permissions are denied';
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw 'Location permissions are permanently denied.';
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      setState(() => _currentPosition = position);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location acquired successfully!')),
        );
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      setState(() => _isLocationLoading = false);
    }
  }

  Future<void> _handleSubmit() async {
    if (!(_formKey.currentState?.saveAndValidate() ?? false)) return;

    final user = _authService.getCurrentUser();
    if (user == null) {
      _showError('Not signed in');
      return;
    }

    final values = _formKey.currentState!.value;
    setState(() => _isSaving = true);

    try {
      final birthday = values['birthday'] as DateTime?;
      final birthdayString =
          birthday != null ? DateFormat('yyyy-MM-dd').format(birthday) : null;

      final payload = {
        'firebaseUid': user.uid,
        'personalInfo': {
          'firstName': values['firstName'] as String? ?? '',
          'lastName': values['lastName'] as String? ?? '',
          'email': values['email'] as String? ?? user.email ?? '',
          'gender': values['gender'] as String?,
          'birthday': birthdayString,
          'sportsInterests': values['sportsInterests'] as List<String>? ?? [],
          'about': values['about'] as String? ?? '',
        },
        'location': _buildLocationPayload(values['neighborhood'] ?? ''),
      };

      await _profileService.updateProfile(payload);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } on DioException catch (e) {
      final msg = e.response?.data is Map
          ? e.response?.data['message']
          : e.response?.data;
      _showError('Error: ${msg ?? e.message}');
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Map<String, dynamic> _buildLocationPayload(String neighborhood) {
    final location = <String, dynamic>{'neighborhood': neighborhood};
    if (_currentPosition != null) {
      location['coordinates'] = {
        'type': 'Point',
        'coordinates': [
          _currentPosition!.longitude,
          _currentPosition!.latitude,
        ],
      };
    } else {
      final existing = _cachedProfile?['location'] as Map<String, dynamic>?;
      final existingCoords = existing?['coordinates'];
      if (existingCoords != null) {
        location['coordinates'] = existingCoords;
      }
    }
    return location;
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Profile')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_loadError != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Profile')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _loadError!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _loadError = null;
                      _isLoading = true;
                    });
                    _loadProfile();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final user = _authService.getCurrentUser();
    final personalInfo = _getPersonalInfoFromCache();
    final initialEmail = personalInfo?['email'] ?? user?.email ?? '';
    final initialFirstName = personalInfo?['firstName'] ?? '';
    final initialLastName = personalInfo?['lastName'] ?? '';
    final initialGender = personalInfo?['gender'] ?? '';
    final initialSports = personalInfo?['sportsInterests'] as List<dynamic>? ?? [];
    final initialAbout = personalInfo?['about'] ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: FormBuilder(
          key: _formKey,
          initialValue: {
            'firstName': initialFirstName,
            'lastName': initialLastName,
            'email': initialEmail,
            'gender': initialGender,
            'sportsInterests': initialSports.map((e) => e.toString()).toList(),
            'about': initialAbout,
            'neighborhood': _cachedNeighborhood ?? '',
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTextField('firstName', 'First Name', Icons.person_outline,
                  validator: FormBuilderValidators.required()),
              const SizedBox(height: 16),
              _buildTextField('lastName', 'Last Name', Icons.person_outline,
                  validator: FormBuilderValidators.required()),
              const SizedBox(height: 16),
              _buildTextField('email', 'Email', Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: FormBuilderValidators.compose([
                    FormBuilderValidators.required(),
                    FormBuilderValidators.email(),
                  ])),
              const SizedBox(height: 16),
              _buildBirthdayField(),
              const SizedBox(height: 16),
              _buildGenderField(),
              const SizedBox(height: 16),
              _buildLocationSection(),
              const SizedBox(height: 16),
              _buildSportsField(),
              const SizedBox(height: 16),
              FormBuilderTextField(
                name: 'about',
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'About yourself',
                  hintText: 'Share your interests...',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                validator: FormBuilderValidators.compose([
                  FormBuilderValidators.maxLength(
                    500,
                    errorText: 'Max 500 characters',
                  ),
                ]),
              ),
              const SizedBox(height: 24),
              _isSaving
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      onPressed: _handleSubmit,
                      child: const Text('Save Changes', style: TextStyle(fontSize: 16)),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Map<String, dynamic>? _cachedProfile;
  String? _cachedNeighborhood;

  Map<String, dynamic>? _getPersonalInfoFromCache() {
    final pi = _cachedProfile?['personalInfo'] as Map<String, dynamic>?;
    if (pi == null) return null;
    final bio = _cachedProfile?['bio'] as Map<String, dynamic>?;
    final result = Map<String, dynamic>.from(pi);
    if (bio?['aboutMe'] != null) result['about'] = bio!['aboutMe'];
    result['sportsInterests'] =
        _cachedProfile?['sportsInterests'] as List<dynamic>? ?? [];
    return result;
  }

  Widget _buildTextField(
    String name,
    String label,
    IconData icon, {
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return FormBuilderTextField(
      name: name,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        prefixIcon: Icon(icon),
      ),
      validator: validator,
    );
  }

  Widget _buildBirthdayField() {
    return FormBuilderField<DateTime>(
      name: 'birthday',
      builder: (FormFieldState<DateTime> field) {
        return InputDecorator(
          decoration: InputDecoration(
            labelText: 'Birthday',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.calendar_today),
            errorText: field.errorText,
          ),
          child: InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedBirthday ??
                    DateTime.now().subtract(const Duration(days: 365 * 18)),
                firstDate: DateTime(1950),
                lastDate: DateTime.now(),
              );
              if (picked != null) {
                setState(() => _selectedBirthday = picked);
                field.didChange(picked);
              }
            },
            child: Text(
              _selectedBirthday != null
                  ? DateFormat('yyyy-MM-dd').format(_selectedBirthday!)
                  : 'Tap to select date',
              style: TextStyle(
                color: _selectedBirthday != null ? Colors.black87 : Colors.grey[600],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGenderField() {
    return FormBuilderDropdown<String>(
      name: 'gender',
      decoration: const InputDecoration(
        labelText: 'Gender',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.wc_outlined),
      ),
      items: const [
        DropdownMenuItem(value: 'male', child: Text('Male')),
        DropdownMenuItem(value: 'female', child: Text('Female')),
        DropdownMenuItem(value: 'other', child: Text('Other')),
      ],
    );
  }

  Widget _buildLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Living Area',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: FormBuilderTextField(
                name: 'neighborhood',
                decoration: const InputDecoration(
                  labelText: 'Neighborhood / City',
                  hintText: 'e.g. Tel Aviv Center',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_city),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              height: 56,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(4),
                color: _currentPosition != null ? Colors.green[50] : null,
              ),
              child: IconButton(
                icon: _isLocationLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        _currentPosition != null
                            ? Icons.my_location
                            : Icons.location_searching,
                        color: _currentPosition != null
                            ? Colors.green
                            : Colors.grey[700],
                      ),
                onPressed: _getCurrentLocation,
                tooltip: 'Use Current Location',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSportsField() {
    return FormBuilderCheckboxGroup<String>(
      name: 'sportsInterests',
      decoration: const InputDecoration(
        labelText: 'Sports Interests',
        border: InputBorder.none,
      ),
      options: _sportsOptions
          .map((s) => FormBuilderFieldOption(value: s, child: Text(s)))
          .toList(),
      wrapSpacing: 8,
      wrapRunSpacing: 8,
    );
  }
}
