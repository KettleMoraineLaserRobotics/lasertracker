import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:lasertracker/core/websocket_service.dart';

class OfflineBanner {
  static void showOfflineBanner(ScaffoldMessengerState scaffoldMessenger) {
    scaffoldMessenger.showMaterialBanner(
      MaterialBanner(
        backgroundColor: Colors.amber,
        content: const Text('Cannot connect to server!', style: TextStyle(color: Colors.black)),
        leading: const Icon(Icons.wifi_off, color: Colors.black),
        actions: [
          TextButton(
            onPressed: () async {
              final token = await FlutterSecureStorage().read(key: 'token');
              WebSocketService.instance.connect(token!);
            },
            child: const Text('RETRY', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  static void hideOfflineBanner(ScaffoldMessengerState scaffoldMessenger) {
    scaffoldMessenger.hideCurrentMaterialBanner();
  }
}
