import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_ce/hive.dart';
import 'package:lasertracker/core/fake_data.dart';
import 'package:go_router/go_router.dart';
import 'package:lasertracker/core/websocket_service.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/api.dart';
import 'package:lasertracker/widgets/error_snack.dart';

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

  @override
  void dispose() {
    groupKeyController.dispose();
    usernameController.dispose();
    pinController.dispose();
    super.dispose();
  }

  Future<void> showUrlDialog() async {
    await showDialog<bool>(context: context, builder: (BuildContext context) => const _ServerUrlDialog());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight - 32),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    Spacer(),
                    Image.asset(
                      "assets/images/tracker_logo-horizontal.png",
                      height: 75,
                      alignment: Alignment.center,
                      color: Theme.of(context).colorScheme.primary,
                      colorBlendMode: BlendMode.srcIn,
                    ),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 750),
                      child: Column(
                        children: [
                          const SizedBox(height: 16),
                          if (useFakeData)
                            Text(
                              "Testing mode is on. Fake data will be used.",
                              style: Theme.of(
                                context,
                              ).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.error),
                            ),
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
                                  String groupKey = groupKeyController.text.toUpperCase();
                                  String username = usernameController.text;
                                  String pin = pinController.text;
                                  if (await groupLogin(groupKey, username, pin) == true) {
                                    final token = await FlutterSecureStorage().read(key: 'token');
                                    WebSocketService.instance.connect(token!);
                                    if (!context.mounted) return;
                                    context.go('/home');
                                  }
                                }
                              } catch (e) {
                                ErrorSnack.showErrorSnackBar(scaffoldMessenger, e);
                              }

                              if (!mounted) return;
                              setState(() {
                                isLoading = false;
                              });
                            },
                      child: Text("Login"),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      child: const Text("Create an account"),
                      onPressed: () => context.push('/account-create'),
                    ),
                    const SizedBox(height: 16),
                    TextButton(child: const Text("Create a group"), onPressed: () => context.push('/group-create')),
                    Spacer(),
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TextButton(
                              onPressed: () => showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: Text('Info', style: Theme.of(context).textTheme.displaySmall),
                                    content: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          "Laser Tracker was developed by FRC Team 2077 Laser Robotics. Laser Tracker uses TheBlueAlliance for event and match data. \n\nVersion: ${Hive.box('meta').get('client_version')}",
                                        ),
                                        SizedBox(height: 32),
                                        Image.asset("assets/images/2077_logo-horizontal.png", width: 400),
                                      ],
                                    ),
                                  );
                                },
                              ),
                              child: Text('About'),
                            ),
                            TextButton(
                              onPressed: () =>
                                  launchUrl(Uri.parse("https://github.com/KettleMoraineLaserRobotics/lasertracker")),
                              child: Text('Github'),
                            ),
                          ],
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: FloatingActionButton(onPressed: showUrlDialog, child: const Icon(Icons.link)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ServerUrlDialog extends StatefulWidget {
  const _ServerUrlDialog();
  @override
  State<_ServerUrlDialog> createState() => _ServerUrlDialogState();
}

class _ServerUrlDialogState extends State<_ServerUrlDialog> {
  final TextEditingController serverURLController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final savedURL = Hive.box('meta').get('server_url');
    if (savedURL != null && savedURL != 'https://api.lasertracker.laserrobotics.org') {
      serverURLController.text = savedURL;
    }
  }

  @override
  void dispose() {
    serverURLController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Laser Tracker Server URL", style: Theme.of(context).textTheme.displaySmall),
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
              controller: serverURLController,
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
            await Hive.box('meta').put(
              'server_url',
              serverURLController.text == "" ? "https://api.lasertracker.laserrobotics.org" : serverURLController.text,
            );
            if (context.mounted) Navigator.pop(context, true);
          },
          child: const Text('Save'),
        ),
        ElevatedButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
      ],
    );
  }
}
