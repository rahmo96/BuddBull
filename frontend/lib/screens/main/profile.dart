import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../services/auth_service.dart';
import '../../services/profile_service.dart';
import '../auth/login_screen.dart';
import 'edit_profile_screen.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.authService});

  /// Optional AuthService for testing. When null, uses default.
  final AuthService? authService;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  AuthService get _authService => widget.authService ?? AuthService();

  final ProfileService _profileService = ProfileService();
  Map<String, dynamic>? _profile;
  bool _isLoading = true;
  String? _loadError;

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

    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final profile = await _profileService.getProfile(user.uid);
      if (mounted) {
        setState(() {
          _profile = profile;
          _isLoading = false;
        });
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        if (mounted) {
          setState(() {
            _profile = null;
            _loadError = null;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _loadError = e.response?.data is Map
                ? e.response?.data['message']
                : e.message;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadError = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _navigateToEditProfile() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => const EditProfileScreen(),
      ),
    );
    if (result == true && mounted) _loadProfile();
  }

  /// Shows the bottom sheet menu (Settings, Logout, etc.)
  void _showSettingsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Settings & Activity",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(height: 30),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text("Settings"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text("Edit Profile"),
              onTap: () {
                Navigator.pop(context);
                _navigateToEditProfile();
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text(
                "Log Out",
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _showLogoutDialog(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Log Out"),
        content: const Text("Are you sure you want to log out?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.pop(context);
              await _authService.signOut();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            child: const Text("Log Out", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  String _displayName() {
    if (_profile == null) return 'User Profile';
    final pi = _profile!['personalInfo'] as Map<String, dynamic>?;
    if (pi == null) return 'User Profile';
    final first = pi['firstName'] as String? ?? '';
    final last = pi['lastName'] as String? ?? '';
    final name = '$first $last'.trim();
    return name.isNotEmpty ? name : 'User Profile';
  }

  String _displayEmail() {
    if (_profile == null) return '';
    final pi = _profile!['personalInfo'] as Map<String, dynamic>?;
    return pi?['email'] as String? ?? '';
  }

  String _displayLocation() {
    if (_profile == null) return '';
    final loc = _profile!['location'] as Map<String, dynamic>?;
    return loc?['neighborhood'] as String? ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Profile"),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.menu_rounded, size: 28),
            onPressed: () => _showSettingsMenu(context),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
              ? Center(
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
                          onPressed: _loadProfile,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const SizedBox(height: 40),
                      const CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.blueGrey,
                        child: Icon(Icons.person, size: 60, color: Colors.white),
                      ),
                      const SizedBox(height: 15),
                      Text(
                        _displayName(),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (_displayEmail().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          _displayEmail(),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                      if (_displayLocation().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.location_on_outlined,
                                size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              _displayLocation(),
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 40),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _navigateToEditProfile,
                          icon: const Icon(Icons.edit_outlined),
                          label: const Text("Edit Profile"),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SettingsScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.settings_outlined),
                          label: const Text("Settings"),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
