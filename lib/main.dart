import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lasertracker/screens/account_create.dart';
import 'package:lasertracker/screens/group_create.dart';
import 'package:lasertracker/screens/home_page.dart';
import 'package:lasertracker/screens/login_page.dart';
import 'package:lasertracker/screens/settings_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/fake_data.dart';
import 'core/theme.dart';

final GoRouter router = GoRouter(
  redirect: (context, state) async {
    final prefs = await SharedPreferences.getInstance();
    final String? groupKey = prefs.getString("loginGroupKey");
    final String? username = prefs.getString("loginUsername");

    final bool isLoggedIn = groupKey != null && username != null;
    final String currentLocation = state.matchedLocation;

    if (isLoggedIn) {
      if (currentLocation == '/login' ||
          currentLocation == '/account-create' ||
          currentLocation == '/group-create') {
        return '/home';
      }
    } else {
      if (currentLocation == '/home') {
        return '/login';
      }
    }

    return null;
  },
  initialLocation: '/login',
  routes: [
    GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
    GoRoute(path: "/settings", builder: (context, state) => const SettingsPage()),
    GoRoute(path: '/account-create', builder: (context, state) => const AccountCreatePage()),
    GoRoute(path: '/group-create', builder: (context, state) => const GroupCreatePage()),
    GoRoute(path: '/home', builder: (context, state) => const HomePage()),
  ],
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (useFakeData) await seedFakeSession();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(title: 'Laser Tracker', theme: laserTheme, routerConfig: router);
  }
}
