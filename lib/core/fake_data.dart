import 'package:shared_preferences/shared_preferences.dart';

// Run with: flutter run -d chrome --dart-define=FAKE_DATA=true
const bool useFakeData = bool.fromEnvironment('FAKE_DATA');

const String fakeTeamNum = "2077";
const String fakeGroupKey = "GRPKEY";
const String fakeEventKey = "2026wimuk";
const String fakeUsername = "you";

final List<Map<String, dynamic>> fakeMembers = [
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

Map<String, dynamic> _member(String username, String name, String role, String job, String location,
    {bool admin = false}) {
  return {
    "username": username,
    "display_name": name,
    "role": role,
    "job": job,
    "location": location,
    "is_admin": admin ? 1 : 0,
  };
}

Map<String, dynamic>? fakeMember(String username) {
  for (final m in fakeMembers) {
    if (m["username"] == username) return m;
  }
  return null;
}

List<Map<String, dynamic>> fakeLogs() {
  final now = DateTime.now().millisecondsSinceEpoch / 1000;
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
      {
        "timestamp": now - i * 420,
        "username": fakeMembers[i % fakeMembers.length]["username"],
        "action": actions[i % actions.length],
      },
  ];
}

// Upcoming quals, one every ~9 minutes, with 2077 rotating through the alliance slots.
List<Map<String, dynamic>> fakeMatches() {
  final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  const others = [
    ["1675", "3692", "7103", "9760", "10522", "930"],
    ["1732", "2614", "3568", "4786", "5199", "6223"],
  ];
  final matches = <Map<String, dynamic>>[];
  for (var i = 0; i < 8; i++) {
    final pool = others[i % 2];
    final red = ["frc${pool[0]}", "frc${pool[1]}", "frc${pool[2]}"];
    final blue = ["frc${pool[3]}", "frc${pool[4]}", "frc${pool[5]}"];
    (i.isEven ? red : blue)[i % 3] = "frc$fakeTeamNum";
    final t = now + 600 + i * 540;
    matches.add({
      "key": "${fakeEventKey}_qm${14 + i * 6}",
      "comp_level": "qm",
      "match_number": 14 + i * 6,
      "actual_time": null,
      "predicted_time": t,
      "time": t - 120,
      "alliances": {
        "red": {"team_keys": red},
        "blue": {"team_keys": blue},
      },
    });
  }
  return matches;
}

const List<Map<String, dynamic>> fakeStreams = [
  {"name": "Day 1", "video_id": "B02_ENFnh-4"},
  {"name": "Day 2", "video_id": "1AAJoRRmcJo"},
];

// Called from main() before runApp so the router redirect sees a logged-in user.
Future<void> seedFakeSession() async {
  final prefs = await SharedPreferences.getInstance();
  final me = fakeMembers.first;

  await prefs.setString("backendURL", "http://example.com");
  await prefs.setString("loginGroupKey", fakeGroupKey);
  await prefs.setString("loginUsername", fakeUsername);
  await prefs.setString("loginPin", "0000");
  await prefs.setString("team_number", fakeTeamNum);
  await prefs.setString("group_name", "Laser Robotics");
  await prefs.setString("event_key", fakeEventKey);
  await prefs.setString("display_name", me["display_name"]);
  await prefs.setString("job", me["job"]);
  await prefs.setString("role", me["role"]);
  await prefs.setString("location", me["location"]);
}
