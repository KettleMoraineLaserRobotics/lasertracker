import 'dart:async';
import 'dart:convert';
import 'package:lasertracker/models/models.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketService {
  WebSocketChannel? channel;
  final StreamController<Map<String, dynamic>> eventController = StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get eventStream => eventController.stream;

  void connect(String jwtToken, int retryCounter) async {
    final prefs = await SharedPreferences.getInstance();
    final serverURL = prefs.getString("backendURL");
    final wsUrl = Uri.parse('$serverURL/ws?token=$jwtToken');

    channel = WebSocketChannel.connect(wsUrl);

    channel!.stream.listen(
      (message) {
        final decoded = jsonDecode(message as String) as Map<String, dynamic>;
        eventController.add(decoded);
      },
      onError: (retryCounter) { // This is probobly a very sloppy solution :/
        if (retryCounter < 5) {
          connect(jwtToken, retryCounter);
        }
      },
    );
  }

  void disconnect() {
    channel?.sink.close();
    eventController.close();
  }

  void handleWSPayload(WSMessage message) {
    switch (message.infoType) {
      case "sync": // Batch of all applicable data
        break;
      case "member": // Info about a member(s)
        // Handle change payload
        break;
      case "battery": // Info about a battery(s)
        // Handle query payload
        break;
      case "group": // Info about the group
        // Handle query payload
        break;
      case "match": // Info about a match(es)

      case "logs":

    }
  }
}