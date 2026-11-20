import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:lasertracker/core/database.dart';
import 'package:lasertracker/core/websocket_service.dart';
import 'package:lasertracker/models/models.dart';

// Run with: flutter run -d chrome --dart-define=FAKE_DATA=true
const bool useFakeData = bool.fromEnvironment('FAKE_DATA');

const int fakeTeamNum = 2077;
const String fakeGroupKey = "GRPKEY";
const String fakeEventKey = "2026wimuk";
const String fakeUsername = "you";
const String fakePin = "0000";

final List<Member> fakeMembers = [
  _member("you", "You (Test User)", "Student", "Safety Captain", "Pits", admin: true),
  _member("sniper", "Sniper", "Lead Coach 1", "Drive Team - Drive Coach", "Queuing/Field", admin: true),
  _member("medic", "Medic", "Student", "Drive Team - Driver", "Queuing/Field"),
  _member("demoman", "Demoman", "Student", "Drive Team - Tech Driver", "Queuing/Field"),
  _member("soldier", "Soldier", "Student", "Drive Team - Technician", "Pits"),
  _member("engineer", "Engineer", "Student", "Student Ambassador", "Stands"),
  _member("pyro", "Pyro", "Mentor", "Impact Award Presenter", "Impact Award room"),
  _member("spy", "Spy", "Mentor", "", "Cafeteria"),
  _member("heavy", "Heavy", "Lead Coach 2", "", "Stands"),
  _member("scout", "Scout", "Student", "", "Quiet Room"),
];

Member _member(String username, String name, String role, String job, String location, {bool admin = false}) => Member()
  ..userName = username
  ..displayName = name
  ..role = role
  ..job = job
  ..location = location
  ..isAdmin = admin;

Member? fakeMember(String username) {
  for (final m in fakeMembers) {
    if (m.userName == username) return m;
  }
  return null;
}

User fakeUser() => User.fromJson(fakeMember(fakeUsername)!.toJson());

final Group fakeGroup = Group()
  ..groupName = "Laser Robotics"
  ..eventKey = fakeEventKey
  ..teamNum = fakeTeamNum
  ..groupkey = fakeGroupKey
  ..teamAvatarB64 = null;

List<LogEntry> fakeLogs() {
  final now = DateTime.now();
  const actions = [
    "changed status to Pits - Safety Captain",
    "changed status to Queuing/Field - Drive Team - Driver",
    "changed status to Stands",
    "changed status to Cafeteria",
    "joined the group",
    "changed status to At Home",
  ];
  return [
    for (var i = 0; i < 30; i++)
      LogEntry()
        ..timestamp = now.subtract(Duration(minutes: i * 7))
        ..requestingUser = (i % 5 == 4 ? fakeMembers[1] : fakeMembers[i % fakeMembers.length]).userName
        ..actionedUser = fakeMembers[i % fakeMembers.length].userName
        ..action = actions[i % actions.length],
  ];
}

List<Match> fakeMatches() {
  final now = DateTime.now();
  const others = [
    [1675, 3692, 7103, 9760, 10522, 930],
    [1732, 2614, 3568, 4786, 5199, 6223],
  ];
  final matches = <Match>[];
  for (var i = 0; i < 10; i++) {
    final teams = List<int>.of(others[i % 2]);
    teams[(i.isEven ? 0 : 3) + i % 3] = fakeTeamNum;
    final matchNum = 2 + i * 6;
    final predicted = now.add(Duration(minutes: (i - 2) * 9 + 10));
    matches.add(
      Match()
        ..matchKey = "${fakeEventKey}_qm$matchNum"
        ..eventKey = fakeEventKey
        ..compLevel = "qm"
        ..setNumber = 1
        ..matchNum = matchNum
        ..red1 = teams[0]
        ..red2 = teams[1]
        ..red3 = teams[2]
        ..blue1 = teams[3]
        ..blue2 = teams[4]
        ..blue3 = teams[5]
        ..predictedTime = predicted
        ..actualTime = i < 2 ? predicted : null,
    );
  }
  return matches;
}

final List<EventStream> fakeStreams = [
  EventStream()
    ..name = "Day 1"
    ..url = "https://www.youtube.com/embed/B02_ENFnh-4"
    ..date = "2026-03-27"
    ..type = "youtube",
  EventStream()
    ..name = "Day 2"
    ..url = "https://www.youtube.com/embed/1AAJoRRmcJo"
    ..date = "2026-03-28"
    ..type = "youtube",
];

List<Battery> fakeBatteries() {
  final now = DateTime.now();
  const statuses = ["In Robot", "Charging", "Charged", "Charged", "Resting", "Dead"];
  return [
    for (var i = 0; i < statuses.length; i++)
      Battery()
        ..name = "2026-${String.fromCharCode(65 + i)}"
        ..status = statuses[i]
        ..matchesUsed = (i * 3) % 7
        ..notes = i == 5 ? "Low voltage under load, don't use" : ""
        ..timestamp = now.subtract(Duration(minutes: i * 11)),
  ];
}

Future<void> seedFakeSession() async {
  await clearDB();
  await Hive.box('meta').put('server_url', 'http://example.com');

  const storage = FlutterSecureStorage();
  await storage.write(key: 'token', value: 'fake-token');
  await storage.write(key: 'group_key', value: fakeGroupKey);
  await storage.write(key: 'username', value: fakeUsername);
  await storage.write(key: 'pin', value: fakePin);

  await putGroup(fakeGroup);
  await putUser(fakeUser());
  for (final m in fakeMembers) {
    await putMember(m);
  }
  for (final l in fakeLogs()) {
    await putLog(l);
  }
  for (final m in fakeMatches()) {
    await putMatch(m);
  }
  for (final s in fakeStreams) {
    await putStream(s);
  }
  for (final b in fakeBatteries()) {
    await putBattery(b);
  }
}
