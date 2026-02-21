import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const _keyNotifications = 'settings_notifications';
  static const _keyDarkMode = 'settings_dark_mode';
  static const _keyActivityReminders = 'settings_activity_reminders';

  Future<bool> getNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyNotifications) ?? true;
  }

  Future<void> setNotificationsEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyNotifications, value);
  }

  Future<bool> getDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyDarkMode) ?? false;
  }

  Future<void> setDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyDarkMode, value);
  }

  Future<bool> getActivityRemindersEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyActivityReminders) ?? true;
  }

  Future<void> setActivityRemindersEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyActivityReminders, value);
  }
}
