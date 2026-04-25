import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/theme/app_theme.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'screens/dashboard_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/login_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/register_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/inventory_screen.dart';
import 'screens/waste_screen.dart';
import 'screens/batch_screen.dart';
import 'screens/reports_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KitchenStock Pro',
      theme: AppTheme.lightTheme,
      initialRoute: '/',
      routes: {
        '/': (context) => const AppEntryPoint(),
        OnboardingScreen.routeName: (context) => const OnboardingScreen(),
        '/login': (context) => const LoginScreen(),
        RegisterScreen.routeName: (context) => const RegisterScreen(),
        ForgotPasswordScreen.routeName: (context) =>
            const ForgotPasswordScreen(),
        DashboardScreen.routeName: (context) => const DashboardScreen(),
        ProfileScreen.routeName: (context) => const ProfileScreen(),
        SettingsScreen.routeName: (context) => const SettingsScreen(),
        '/inventory': (context) => const InventoryScreen(),
        '/waste': (context) => const WasteScreen(),
        '/batch': (context) => const BatchScreen(),
        '/reports': (context) => const ReportsScreen(),
      },
    );
  }
}

class AppEntryPoint extends StatefulWidget {
  const AppEntryPoint({super.key});

  @override
  State<AppEntryPoint> createState() => _AppEntryPointState();
}

class _AppEntryPointState extends State<AppEntryPoint> {
  late final Future<bool> _onboardingFuture = _hasSeenOnboarding();
  final AuthService _authService = AuthService();

  Future<bool> _hasSeenOnboarding() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(OnboardingScreen.preferenceKey) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _onboardingFuture,
      builder: (context, onboardingSnapshot) {
        if (onboardingSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final hasSeenOnboarding = onboardingSnapshot.data ?? false;
        if (!hasSeenOnboarding) {
          return const OnboardingScreen();
        }

        return StreamBuilder<User?>(
          stream: _authService.authStateChanges(),
          builder: (context, authSnapshot) {
            if (authSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (authSnapshot.hasData) {
              return const DashboardScreen();
            }

            return const RegisterScreen();
          },
        );
      },
    );
  }
}
