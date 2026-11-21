part of 'models.dart';

class Group {
  String? groupName;
  String? eventKey;
  int? teamNum;
  String? teamAvatarB64;
  String? groupkey;

  Group();

  factory Group.fromJson(Map<String, dynamic> json) => Group()
    ..groupName = json['group_name'] as String?
    ..eventKey = json['event_key'] as String?
    ..teamNum = _asInt(json['team_number'])
    ..teamAvatarB64 = json['avatar_image'] as String?
    ..groupkey = json['group_key'] as String?;

  Map<String, dynamic> toJson() => {
    'group_name': groupName,
    'event_key': eventKey,
    'team_number': teamNum,
    'avatar_image': teamAvatarB64,
    'group_key': groupkey,
  };

  static final Map<String, Uint8List> avatarCache = {};

  Image teamAvatar() {
    final b64 = teamAvatarB64;
    if (b64 == null || b64.isEmpty || b64 == "none") {
      return Image.asset("assets/images/first_icon.png", height: 75, alignment: Alignment.center);
    } else {
      final bytes = avatarCache.putIfAbsent(b64, () => base64Decode(b64));
      return Image.memory(bytes, gaplessPlayback: true);
    }
  }

  void changeEventKey(String newKey) {}
}
