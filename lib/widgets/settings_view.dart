import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:lasertracker/core/database.dart';
import 'package:lasertracker/core/websocket_service.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Column(
          children: [
            
            ElevatedButton(
              onPressed: () {
                clearDB();
                WebSocketService.instance.requestSync();
                if (!context.mounted) return;
                context.go('/home');
              },
              child: const Text("Force Sync"),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text('Log out'),
                      content: const Text('Are you sure you want to log out.'),
                      actions: <Widget>[
                        ElevatedButton(
                          onPressed: () async {
                            await const FlutterSecureStorage().delete(key: 'token');
                            await clearDB();
                            if (!context.mounted) return;
                            context.go('/login');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            textStyle: const TextStyle(color: Colors.white),
                          ),
                          child: const Text('Yes'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text('No'),
                        ),
                      ],
                    );
                  },
                );
              },
              child: const Text('Log out'),
            ),
          ],
        ),
      ],
    );
  }
}
