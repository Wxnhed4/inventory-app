import 'package:shared_preferences/shared_preferences.dart';

class AppPreferencesService {
  static const String notificationsKey = 'notifications_enabled';
  static const String compactModeKey = 'compact_mode_enabled';

  Future<bool> getNotificationsEnabled() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(notificationsKey) ?? true;
  }

  Future<void> setNotificationsEnabled(bool value) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(notificationsKey, value);
  }

  Future<bool> getCompactModeEnabled() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(compactModeKey) ?? false;
  }

  Future<void> setCompactModeEnabled(bool value) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(compactModeKey, value);
  }

  Future<void> resetOnboarding() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool('seen_onboarding', false);
  }
}
