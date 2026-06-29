import 'package:buddbull/core/locale/l10n_extension.dart';
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
      final l10n = context.l10n;
      setState(() => _notificationsEnabled = value);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(value ? l10n.notificationsEnabled : l10n.notificationsDisabled),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _setDarkMode(bool value) async {
    await _settingsService.setDarkMode(value);
    if (mounted) {
      final l10n = context.l10n;
      setState(() => _darkMode = value);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(value ? l10n.darkModeEnabled : l10n.darkModeDisabled),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _setActivityReminders(bool value) async {
    await _settingsService.setActivityRemindersEnabled(value);
    if (mounted) {
      final l10n = context.l10n;
      setState(() => _activityReminders = value);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(value ? l10n.remindersEnabled : l10n.remindersDisabled),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.settingsTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Text(
              l10n.sectionNotifications,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.notifications_outlined),
            title: Text(l10n.pushNotifications),
            subtitle: Text(l10n.pushNotificationsSubtitle),
            value: _notificationsEnabled,
            onChanged: _setNotifications,
          ),
          SwitchListTile(
            secondary: const Icon(Icons.alarm_outlined),
            title: Text(l10n.activityReminders),
            subtitle: Text(l10n.activityRemindersSubtitle),
            value: _activityReminders,
            onChanged: _setActivityReminders,
          ),
          const Divider(height: 24),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text(
              l10n.sectionAppearance,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.dark_mode_outlined),
            title: Text(l10n.darkMode),
            subtitle: Text(l10n.darkModeSubtitle),
            value: _darkMode,
            onChanged: _setDarkMode,
          ),
          const Divider(height: 24),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text(
              l10n.sectionAbout,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(l10n.appVersion),
            subtitle: const Text('1.0.0'),
          ),
        ],
      ),
    );
  }
}
