part of 'models.dart';

@collection
class Battery {
  Id id = Isar.autoIncrement;
  String? name;
  String? status;
  int? matchesUsed;
  String? notes;
  DateTime? timestamp;

  void addBattery() {}

  void removeBattery() {}

  void changeBatteryStatus() {}
}