import 'package:flutter/material.dart';
import '../../services/settings_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SettingsService _settingsService = SettingsService();

  bool _notificationsEnabled = true;
  bool _darkMode = false;
  bool _activityReminders = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final notifications = await _settingsService.getNotificationsEnabled();
    final darkMode = await _settingsService.getDarkMode();
    final reminders = await _settingsService.getActivityRemindersEnabled();

    if (mounted) {
      setState(() {
        _notificationsEnabled = notifications;
        _darkMode = darkMode;
        _activityReminders = reminders;
        _isLoading = false;
      });
    }
  }

  Future<void> _setNotifications(bool value) async {
    await _settingsService.setNotificationsEnabled(value);
    if (mounted) {
      setState(() => _notificationsEnabled = value);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(value ? 'Notifications enabled' : 'Notifications disabled'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _setDarkMode(bool value) async {
    await _settingsService.setDarkMode(value);
    if (mounted) {
      setState(() => _darkMode = value);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(value ? 'Dark mode on' : 'Dark mode off'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _setActivityReminders(bool value) async {
    await _settingsService.setActivityRemindersEnabled(value);
    if (mounted) {
      setState(() => _activityReminders = value);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(value ? 'Activity reminders on' : 'Activity reminders off'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Settings')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Text(
              'Notifications',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.notifications_outlined),
            title: const Text('Push Notifications'),
            subtitle: const Text('Receive notifications about activities'),
            value: _notificationsEnabled,
            onChanged: _setNotifications,
          ),
          SwitchListTile(
            secondary: const Icon(Icons.alarm_outlined),
            title: const Text('Activity Reminders'),
            subtitle: const Text('Remind me before scheduled activities'),
            value: _activityReminders,
            onChanged: _setActivityReminders,
          ),
          const Divider(height: 24),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text(
              'Appearance',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.dark_mode_outlined),
            title: const Text('Dark Mode'),
            subtitle: const Text('Use dark theme'),
            value: _darkMode,
            onChanged: _setDarkMode,
          ),
          const Divider(height: 24),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text(
              'About',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('App Version'),
            subtitle: const Text('1.0.0'),
          ),
        ],
      ),
    );
  }
}
