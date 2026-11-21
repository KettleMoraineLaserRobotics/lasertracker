import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'dart:async';

import 'package:lasertracker/models/models.dart';

const List<String> boxNames = ['members', 'batteries', 'logs', 'group', 'matches', 'streams', 'meta', 'user'];

Future<void> initDB() async {
  await Hive.initFlutter();
  for (final name in boxNames) {
    await Hive.openBox(name);
  }
  final serverURL = Hive.box('meta').get('server_url');
  Hive.box(
    'meta',
  ).put('client_version', "Prerelease"); // CHANGE ME EACH UPDATE PLEASE <3!! (yy.mm.dd versioning please too)
  if (serverURL == null || serverURL == "") {
    Hive.box('meta').put('server_url', 'https://api.lasertracker.laserrobotics.org');
  }
}

Future<void> clearDB() async {
  for (final name in boxNames) {
    if (name == 'meta') continue;
    await Hive.box(name).clear();
  }
}

Map<String, dynamic> _asJson(dynamic raw) => Map<String, dynamic>.from(raw as Map);

List<T> _readAll<T>(String boxName, T Function(Map<String, dynamic>) fromJson) =>
    Hive.box(boxName).values.map((e) => fromJson(_asJson(e))).toList();

List<Member> getMembers() => _readAll('members', Member.fromJson);

List<Battery> getBatteries() => _readAll('batteries', Battery.fromJson);

List<LogEntry> getLogs() => _readAll('logs', LogEntry.fromJson);

List<EventStream> getStreams() => _readAll('streams', EventStream.fromJson);

List<Match> getMatches() => _readAll('matches', Match.fromJson);

Group getGroup() {
  final box = Hive.box('group');
  if (box.isEmpty) return Group();
  return Group.fromJson(_asJson(box.getAt(0)));
}

User getUser() {
  final box = Hive.box('user');
  if (box.isEmpty) return User();
  return User.fromJson(_asJson(box.getAt(0)));
}
