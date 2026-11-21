import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:lasertracker/models/models.dart';

class LogView extends StatelessWidget {
  const LogView({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Box>(
      valueListenable: Hive.box('logs').listenable(),
      builder: (context, box, _) {
        final logs = box.values.map((e) => LogEntry.fromJson(Map<String, dynamic>.from(e as Map))).toList()
          ..sort((a, b) => b.timestamp!.compareTo(a.timestamp!));

        if (logs.isEmpty) {
          return Center(child: Text("No logs yet", style: Theme.of(context).textTheme.bodyLarge));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: logs.length,
          itemBuilder: (context, index) {
            final log = logs[index];
            return Text("[${log.timestamp}] ${log.requestingUser} ${log.action} ${log.actionedUser}");
          },
        );
      },
    );
  }
}
