import 'package:material_ui/material_ui.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:lasertracker/core/websocket_service.dart';
import 'package:lasertracker/screens/account_create.dart';
import 'package:lasertracker/screens/group_create.dart';
import 'package:lasertracker/screens/home_page.dart';
import 'package:lasertracker/screens/login_page.dart';
import 'package:lasertracker/widgets/offline_banner.dart';
import 'core/database.dart';
import 'core/fake_data.dart';
import 'core/theme.dart';

final GoRouter router = GoRouter(
  redirect: (context, state) async {
    WidgetsFlutterBinding.ensureInitialized();
    final token = await const FlutterSecureStorage().read(key: 'token');
    final isLoggedIn = token != null && token.isNotEmpty;
    final String currentLocation = state.matchedLocation;

    if (isLoggedIn) {
      if (currentLocation == '/login' || currentLocation == '/account-create' || currentLocation == '/group-create') {
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
    GoRoute(path: '/account-create', builder: (context, state) => const AccountCreatePage()),
    GoRoute(path: '/group-create', builder: (context, state) => const GroupCreatePage()),
    GoRoute(path: '/home', builder: (context, state) => const HomePage()),
  ],
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initDB();
  if (useFakeData) await seedFakeSession();
  final token = await const FlutterSecureStorage().read(key: 'token');
  if (token != null && token.isNotEmpty) WebSocketService.instance.connect(token);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Laser Tracker',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: router,
      builder: (context, child) => Stack(
        children: [
          child!,
          const Positioned(top: 0, left: 0, right: 0, child: OfflineBanner()),
        ],
      ),
    );
  }
}
