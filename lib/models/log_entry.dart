part of 'models.dart';

class LogEntry {
  String? requestingUser;
  String? actionedUser; // differs from requestingUser when someone acts on another member
  String? action;
  DateTime? timestamp;

  LogEntry();

  factory LogEntry.fromJson(Map<String, dynamic> json) => LogEntry()
    ..requestingUser = json['requesting_user'] as String?
    ..actionedUser = json['actioned_user'] as String?
    ..action = json['action'] as String?
    ..timestamp = _parseTime(json['timestamp']);

  Map<String, dynamic> toJson() => {
    'requesting_user': requestingUser,
    'actioned_user': actionedUser,
    'action': action,
    'timestamp': timestamp?.toUtc().toIso8601String(),
  };
}
