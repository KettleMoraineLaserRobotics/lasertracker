part of 'models.dart';

class Member {
  String? userName;
  String? displayName;
  String? job;
  String? role;
  String? location;
  bool? isAdmin;

  Member();

  factory Member.fromJson(Map<String, dynamic> json) => Member()
    ..userName = json['username'] as String?
    ..displayName = json['display_name'] as String?
    ..job = json['job'] as String?
    ..role = json['role'] as String?
    ..location = json['location'] as String?
    ..isAdmin = json['is_admin'] as bool?;

  Map<String, dynamic> toJson() => {
    'username': userName,
    'display_name': displayName,
    'job': job,
    'role': role,
    'location': location,
    'is_admin': isAdmin,
  };

  Future<void> updateMember({String? job, String? location, bool? isAdmin}) {
    final payload = toJson();
    if (job != null) payload['job'] = job;
    if (location != null) payload['location'] = location;
    if (isAdmin != null) payload['is_admin'] = isAdmin;
    return WebSocketService.instance.sendRequest('UPDATE_MEMBER', payload);
  }

  Future<void> setJob(String newJob) => updateMember(job: newJob);

  Future<void> setRole(String newRole) =>
      WebSocketService.instance.sendRequest('CHANGE_MEMBER_ROLE', {'username': userName, 'role': newRole});

  Future<void> setLocation(String newLocation) => updateMember(location: newLocation);

  Future<void> setAdmin(bool newValue) => updateMember(isAdmin: newValue);

  Future<void> removeMember() => WebSocketService.instance.sendRequest('REMOVE_MEMBER', {'username': userName});

  Future<void> changePin(String newPin) =>
      WebSocketService.instance.sendRequest('CHANGE_PIN', {'username': userName, 'new_pin': newPin});
}
