import 'package:buddbull/l10n/l10n.dart';
import 'package:buddbull/services/settings_service.dart';
import 'package:flutter/material.dart';

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
          content: Text(value ? context.l10n.settingsNotificationsOn : context.l10n.settingsNotificationsOff),
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
          content: Text(value ? context.l10n.settingsDarkOn : context.l10n.settingsDarkOff),
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
          content: Text(value ? context.l10n.settingsRemindersOn : context.l10n.settingsRemindersOff),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(context.l10n.settingsTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.settingsTitle)),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Text(
              context.l10n.settingsNotificationsSection,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.notifications_outlined),
            title: Text(context.l10n.settingsPush),
            subtitle: Text(context.l10n.settingsPushHint),
            value: _notificationsEnabled,
            onChanged: _setNotifications,
          ),
          SwitchListTile(
            secondary: const Icon(Icons.alarm_outlined),
            title: Text(context.l10n.settingsReminders),
            subtitle: Text(context.l10n.settingsRemindersHint),
            value: _activityReminders,
            onChanged: _setActivityReminders,
          ),
          const Divider(height: 24),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text(
              context.l10n.settingsAppearance,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.dark_mode_outlined),
            title: Text(context.l10n.settingsDarkMode),
            subtitle: Text(context.l10n.settingsDarkModeHint),
            value: _darkMode,
            onChanged: _setDarkMode,
          ),
          const Divider(height: 24),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text(
              context.l10n.settingsAbout,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(context.l10n.settingsAppVersion),
            subtitle: const Text('1.0.0'),
          ),
        ],
      ),
    );
  }
}
