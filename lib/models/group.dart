part of 'models.dart';

@collection
class Group {
  Id id = Isar.autoIncrement;
  String? groupName;
  String? eventKey;
  int? teamNum;
  String? teamAvatarB64;
  String? groupkey;

  Image teamAvatar() {
    return Image.memory(base64Decode(teamAvatarB64!));
  }

  void changeEventKey(String newKey) {}
}