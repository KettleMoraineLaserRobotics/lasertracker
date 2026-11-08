part of 'models.dart';

@collection
class Member {
  Id id = Isar.autoIncrement;
  String? userName;
  String? displayName;
  String? job;
  String? role;
  String? location;
  bool? isAdmin;

  void setJob() {}

  void setRole() {}

  void setLocation() {}

  void removeMember() {}

  void changePin(String newPin) {}
}
