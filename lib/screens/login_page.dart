import 'package:flutter/material.dart';
import 'package:lasertracker/core/fake_data.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import '../core/api.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController groupKeyController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController pinController = TextEditingController();
  bool isLoading = false;

  static const bool useFakeData = bool.fromEnvironment('FAKE_DATA');

  Future<void> loadData() async {
    if (useFakeData) {
      groupKeyController.text = "FAKE2077";
      usernameController.text = "you";
      pinController.text = "0000";
    } else {
      final prefs = await SharedPreferences.getInstance();
      groupKeyController.text = prefs.getString("loginGroupKey") ?? '';
      usernameController.text = prefs.getString("loginUsername") ?? '';
      pinController.text = prefs.getString("loginPin") ?? '';
    }
  }

  @override
  void dispose() {
    groupKeyController.dispose();
    usernameController.dispose();
    pinController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> showUrlDialog() async {
    final prefs = await SharedPreferences.getInstance();
    final backendURLController = TextEditingController(text: prefs.getString('backendURL') ?? '');
    if (!mounted) return;
    await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Laser Tracker Server URL"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Set the URL of the Laser Tracker Server instance. Leave it blank to use the default.",
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: backendURLController,
                  decoration: const InputDecoration(
                    labelText: "https://api.lasertracker.laserrobotics.org",
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            ElevatedButton(
              onPressed: () async {
                await prefs.setString(
                  'backendURL',
                  backendURLController.text == "" ? "https://api.lasertracker.laserrobotics.org" : backendURLController.text,
                );
                if (context.mounted) Navigator.pop(context, true);
              },
              child: const Text('Save'),
            ),
            ElevatedButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ],
        );
      },
    );
    backendURLController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Spacer(),
              Image.asset("assets/images/tracker_logo-horizontal.png", height: 75, alignment: Alignment.center),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 750),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    if (useFakeData) const Text("Testing mode is on. Fake data will be used.", style: TextStyle(color: Colors.red),),
                    const SizedBox(height: 16),
                    TextField(
                      controller: groupKeyController,
                      decoration: const InputDecoration(labelText: 'Group Code', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: usernameController,
                      decoration: const InputDecoration(labelText: 'Username', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: pinController,
                      decoration: const InputDecoration(labelText: 'PIN', border: OutlineInputBorder()),
                      obscureText: true,
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: isLoading
                    ? null
                    : () async {
                        final scaffoldMessenger = ScaffoldMessenger.of(context);

                        setState(() {
                          isLoading = true;
                        });

                        try {
                          if (useFakeData) {
                            await seedFakeSession();
                            context.go('/home');
                          } else {
                            String groupKey = groupKeyController.text;
                            String username = usernameController.text;
                            String pin = pinController.text;
                            if (await groupLogin(groupKey, username, pin) == true) {
                              context.go('/home');
                            }
                          }
                        } catch (e) {
                          scaffoldMessenger.showSnackBar(
                            SnackBar(
                              content: Text("Error: ${e.toString()}"),
                              behavior: SnackBarBehavior.floating,
                              margin: const EdgeInsets.all(16),
                            ),
                          );
                        }

                        setState(() {
                          isLoading = false;
                        });
                      },
                child: Text("Login"),
              ),
              const SizedBox(height: 16),
              TextButton(child: const Text("Create an account"), onPressed: () => context.push('/account-create')),
              const SizedBox(height: 16),
              TextButton(child: const Text("Create a group"), onPressed: () => context.push('/group-create')),
              Spacer(),
              Row(
                children: [
                  Spacer(),
                  FloatingActionButton(onPressed: showUrlDialog, child: const Icon(Icons.link)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
