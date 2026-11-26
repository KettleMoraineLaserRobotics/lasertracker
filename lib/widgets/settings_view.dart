import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:lasertracker/core/api.dart';
import 'package:lasertracker/core/database.dart';
import 'package:lasertracker/core/websocket_service.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  final TextEditingController eventSelectorController = TextEditingController();
  String eventCode = "";

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.asset(
              "assets/images/tracker_logo-horizontal.png",
              height: 75,
              alignment: Alignment.center,
              color: Theme.of(context).colorScheme.primary,
              colorBlendMode: BlendMode.srcIn,
            ),
            SizedBox(height: 16),
            Text('Client Version: ${Hive.box('meta').get('client_version')}'),
            Text('Server Name: ${Hive.box('meta').get('instance_name')}'),
            Text('Server URL: ${Hive.box('meta').get('server_url')}'),
            Text('Server Version: ${Hive.box('meta').get('server_version')}'),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                WebSocketService.instance.enqueue(clearDB);
                WebSocketService.instance.requestSync();
                context.go('/home');
              },
              child: const Text("Force Sync"),
            ),
            Text(
              '  Deletes all local stores and refreshes from the server',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            SizedBox(height: 16),
            ValueListenableBuilder(
              valueListenable: Hive.box('user').listenable(),
              builder: (context, _, _) {
                if (getUser().isAdmin != true) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Text('Change Event', style: Theme.of(context).textTheme.displaySmall),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('Select the event your group is now participating in.'),
                                  SizedBox(height: 16),
                                  FutureBuilder<List<dynamic>>(
                                    future: getEvents(getGroup().teamNum.toString()),
                                    builder: (context, snapshot) {
                                      if (snapshot.hasError) {
                                        return Center(
                                          child: Text(
                                            "Error fetching events",
                                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                              color: Theme.of(context).colorScheme.error,
                                            ),
                                          ),
                                        );
                                      }
                                      if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
                                        final entries =
                                            snapshot.data?.map<DropdownMenuEntry<Object?>>((item) {
                                              if (item is Map && item.length == 1) {
                                                final displayName = item.keys.first.toString();
                                                final value = item.values.first;
                                                return DropdownMenuEntry<Object?>(value: value, label: displayName);
                                              }
                                              return DropdownMenuEntry<Object?>(value: item, label: item.toString());
                                            }).toList() ??
                                            [];
                                        return DropdownMenu<Object?>(
                                          controller: eventSelectorController,
                                          enableFilter: true,
                                          requestFocusOnTap: true,
                                          inputDecorationTheme: InputDecorationTheme(border: OutlineInputBorder()),
                                          label: Text("Select Event"),
                                          onSelected: (value) {
                                            eventCode = value.toString();
                                          },
                                          dropdownMenuEntries: entries,
                                        );
                                      }
                                      return const Center(
                                        child: Padding(
                                          padding: EdgeInsets.all(16),
                                          child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator()),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                              actions: <Widget>[
                                ElevatedButton(
                                  onPressed: () {
                                    WebSocketService.instance.sendRequest("UPDATE_GROUP_EVENT_KEY", {
                                      "event_key": eventCode,
                                    });
                                    Navigator.pop(context);
                                  },
                                  child: const Text('Change Event'),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  child: const Text('Cancel'),
                                ),
                              ],
                            );
                          },
                        );
                      },
                      child: const Text('Change Event'),
                    ),
                    Text(
                      '  Change the event your group tracks. Useful at competitions with multiple divisions.',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Text('Delete Group', style: Theme.of(context).textTheme.displaySmall),
                              content: const Text(
                                'Are you sure you want to delete this group? This cannot be reversed.',
                              ),
                              actions: <Widget>[
                                ElevatedButton(
                                  onPressed: () {
                                    WebSocketService.instance.send('REMOVE_GROUP');
                                    Navigator.pop(context);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Theme.of(context).colorScheme.error,
                                    foregroundColor: Theme.of(context).colorScheme.onError,
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
                      child: const Text('Delete group'),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text('Log out', style: Theme.of(context).textTheme.displaySmall),
                      content: const Text('Are you sure you want to log out?'),
                      actions: <Widget>[
                        ElevatedButton(
                          onPressed: () async {
                            await WebSocketService.instance.logOut();
                            if (!context.mounted) return;
                            context.go('/login');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.error,
                            foregroundColor: Theme.of(context).colorScheme.onError,
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
