import 'package:material_ui/material_ui.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:lasertracker/core/api.dart';
import 'package:lasertracker/core/websocket_service.dart';

class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final ws = WebSocketService.instance;
    return ListenableBuilder(
      listenable: Listenable.merge([ws.status, ws.wantsConnection]),
      builder: (context, _) {
        final show = ws.wantsConnection.value && ws.status.value != WSSSatus.connected;
        final outdated = ws.status.value == WSSSatus.outdated;
        return AnimatedSlide(
          offset: show ? Offset.zero : const Offset(0, -1),
          duration: const Duration(milliseconds: 200),
          child: show
              ? Material(
                  color: outdated ? Colors.redAccent : Colors.amber,
                  child: SafeArea(
                    bottom: false,
                    child: ListTile(
                      leading: Icon(outdated ? Icons.system_update : Icons.wifi_off, color: Colors.black),
                      title: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            outdated ? 'Must update client to connect!' : 'Cannot connect to server!',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.black),
                          ),
                          Text(
                            outdated
                                ? "Client: ${Hive.box('meta').get('client_version')}, Server: ${getServerInfo()}"
                                : "Server URL: ${Hive.box('meta').get('server_url')}",
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black),
                          ),
                        ],
                      ),
                      trailing: outdated
                          ? SizedBox.shrink()
                          : TextButton(
                              onPressed: () async {
                                final token = await const FlutterSecureStorage().read(key: 'token');
                                if (token != null) ws.connect(token);
                              },
                              child: Text(
                                'RETRY',
                                style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.black),
                              ),
                            ),
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        );
      },
    );
  }
}
