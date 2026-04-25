import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../custom_drawer.dart';
import '../screens/onboarding_screen.dart';
import '../services/app_preferences_service.dart';
import '../widgets/section_card.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  static const String routeName = '/settings';

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AppPreferencesService _preferencesService = AppPreferencesService();
  bool _notificationsEnabled = true;
  bool _compactModeEnabled = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final notifications = await _preferencesService.getNotificationsEnabled();
    final compactMode = await _preferencesService.getCompactModeEnabled();

    if (!mounted) return;
    setState(() {
      _notificationsEnabled = notifications;
      _compactModeEnabled = compactMode;
      _isLoading = false;
    });
  }

  Future<void> _toggleNotifications(bool value) async {
    await _preferencesService.setNotificationsEnabled(value);
    if (!mounted) return;
    setState(() {
      _notificationsEnabled = value;
    });
  }

  Future<void> _toggleCompactMode(bool value) async {
    await _preferencesService.setCompactModeEnabled(value);
    if (!mounted) return;
    setState(() {
      _compactModeEnabled = value;
    });
  }

  Future<void> _replayOnboarding() async {
    await _preferencesService.resetOnboarding();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(
      context,
      OnboardingScreen.routeName,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      drawer: const CustomDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionHeading(
                        title: 'Experience',
                        subtitle:
                            'Small preferences that make the app feel more personal and presentation-ready.',
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        value: _notificationsEnabled,
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Enable alerts'),
                        subtitle: const Text(
                          'Use this to highlight low-stock and activity reminders.',
                        ),
                        onChanged: _toggleNotifications,
                      ),
                      SwitchListTile(
                        value: _compactModeEnabled,
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Compact dashboard mode'),
                        subtitle: const Text(
                          'A simple preference placeholder for future layout personalization.',
                        ),
                        onChanged: _toggleCompactMode,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionHeading(
                        title: 'Presentation Tools',
                        subtitle:
                            'Useful shortcuts when you are showing the app to your supervisor or panel.',
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor:
                              AppColors.accent.withValues(alpha: 0.12),
                          foregroundColor: AppColors.accent,
                          child: const Icon(Icons.slideshow_outlined),
                        ),
                        title: const Text('Replay onboarding'),
                        subtitle: const Text(
                          'Start the intro flow again to demonstrate the app story.',
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: _replayOnboarding,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
