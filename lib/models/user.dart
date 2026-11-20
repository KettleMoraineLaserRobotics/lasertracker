part of 'models.dart';

class User extends Member {
  User();

  Future<void> setOwnJob(String newJob) => setJob(newJob);

  Future<void> setOwnRole(String newRole) => setRole(newRole);

  Future<void> setOwnLocation(String newLocation) => setLocation(newLocation);

  factory User.fromJson(Map<String, dynamic> json) => User()
    ..userName = json['username'] as String?
    ..displayName = json['display_name'] as String?
    ..job = json['job'] as String?
    ..role = json['role'] as String?
    ..location = json['location'] as String?
    ..isAdmin = json['is_admin'] as bool?;
}
