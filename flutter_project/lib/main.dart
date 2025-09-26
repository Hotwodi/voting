import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/user_profile_screen.dart';
import 'screens/poll_creation_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/onboarding_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Polygon Voting App',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeScreen(),
        '/admin': (context) => const AdminDashboardScreen(),
        '/profile': (context) => const UserProfileScreen(),
        '/create-poll': (context) => const PollCreationScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/notifications': (context) => const NotificationsScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
      },
    );
  }
}
