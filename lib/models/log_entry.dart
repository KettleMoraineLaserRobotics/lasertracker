part of 'models.dart';

@collection
class LogEntry {
  Id id = Isar.autoIncrement;
  String? username;
  String? action;
  DateTime? timestamp;
}
