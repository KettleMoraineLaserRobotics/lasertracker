import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_ce_flutter/adapters.dart';
import 'package:http/http.dart' as http;
import 'package:lasertracker/core/fake_data.dart';
import 'package:lasertracker/core/websocket_service.dart';
import 'package:lasertracker/models/models.dart';

Future<void> saveSessionData(Map<String, dynamic> data) async {
  for (final entry in data.entries) {
    final key = entry.key;
    final value = entry.value;
    if (key == "member_info") {
    } else if (key == "group_info") {
      putGroup(Group.fromJson(value));
    } else if (key == "token") {
      await FlutterSecureStorage().write(key: "token", value: value);
    }
  }
}

String errorMessage(String action, http.Response response) {
  final body = response.body.trim();
  return body.isEmpty ? "$action: ${response.statusCode}" : "$action: $body (${response.statusCode})";
}

Future<bool> groupLogin(String groupKey, String username, String pin) async {
  final serverURL = Hive.box('meta').get('server_url');

  final response = await http.post(
    Uri.parse("$serverURL/login"),
    headers: {"Content-Type": "application/json"},
    body: jsonEncode({"group_key": groupKey, "username": username, "pin": pin}),
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    const storage = FlutterSecureStorage();
    await storage.write(key: 'group_key', value: groupKey);
    await storage.write(key: 'username', value: username);
    await storage.write(key: 'pin', value: pin);
    await storage.write(key: 'token', value: data['token']);
    return true;
  } else {
    throw Exception(errorMessage("Failed to login", response));
  }
}

Future<bool> memberAdd(String username, String displayName, String pin, String groupKey) async {
  final serverURL = Hive.box('meta').get('server_url');

  final response = await http.post(
    Uri.parse("$serverURL/account"),
    headers: {"Content-Type": "application/json"},
    body: jsonEncode({"group_key": groupKey, "username": username, "display_name": displayName, "pin": pin}),
  );

  if (response.statusCode == 201) {
    final data = jsonDecode(response.body);
    const storage = FlutterSecureStorage();
    await storage.write(key: 'group_key', value: groupKey);
    await storage.write(key: 'username', value: username);
    await storage.write(key: 'pin', value: pin);
    await storage.write(key: 'token', value: data['token']);
    return true;
  } else {
    throw Exception(errorMessage("Failed to join group", response));
  }
}

Future<bool> groupCreate(
  String groupName,
  String eventKey,
  String teamNum,
  String username,
  String displayName,
  String pin,
) async {
  final serverURL = Hive.box('meta').get('server_url');

  final response = await http.post(
    Uri.parse("$serverURL/group"),
    headers: {"Content-Type": "application/json"},
    body: jsonEncode({
      "group_name": groupName,
      "event_key": eventKey,
      "team_number": int.parse(teamNum),
      "username": username,
      "display_name": displayName,
      "pin": pin,
    }),
  );

  if (response.statusCode == 201) {
    final data = jsonDecode(response.body);
    const storage = FlutterSecureStorage();
    await storage.write(key: 'group_key', value: data['group_info']?['group_key']);
    await storage.write(key: 'username', value: username);
    await storage.write(key: 'pin', value: pin);
    await storage.write(key: 'token', value: data['token']);
    return true;
  } else {
    throw Exception(errorMessage("Failed to create group", response));
  }
}

Future<String> getTeamName(String teamNum) async {
  final serverURL = Hive.box('meta').get('server_url');

  final response = await http.get(Uri.parse("$serverURL/tba/team/$teamNum"));
  if (response.statusCode == 200) {
    return jsonDecode(response.body)["team_name"];
  }
  return "Unknown Team";
}

Future<Image> getTeamAvatar(String teamNum) async {
  if (useFakeData) {
    return Image.asset("assets/images/avatar.png");
  }

  final serverURL = Hive.box('meta').get('server_url');

  final response = await http.get(Uri.parse("$serverURL/tba/team/$teamNum"));
  if (response.statusCode == 200) {
    String b64Image = jsonDecode(response.body)["team_avatar_b64"];
    if (b64Image == "") {
      return Image.asset("assets/images/first_icon.png");
    }
    return Image.memory(base64Decode(b64Image));
  } else {
    return Image.asset("assets/images/first_icon.png");
  }
}

Future<List<dynamic>> getEvents(String teamNum) async {
  final serverURL = Hive.box('meta').get('server_url');

  final response = await http.get(Uri.parse("$serverURL/tba/team/$teamNum/events"));
  if (response.statusCode == 200) {
    List data = jsonDecode(response.body);
    return data.map((event) => {event["event_name"]: event["event_key"]}).toList();
  } else {
    throw Exception(errorMessage("Failed to load events", response));
  }
}
