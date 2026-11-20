part of 'models.dart';

class Battery {
  String? name;
  String? status;
  int? matchesUsed;
  String? notes;
  DateTime? timestamp;

  Battery();

  factory Battery.fromJson(Map<String, dynamic> json) => Battery()
    ..name = json['name'] as String?
    ..status = json['status'] as String?
    ..matchesUsed = _asInt(json['matches_used'])
    ..notes = json['notes'] as String?
    ..timestamp = _parseTime(json['timestamp']);

  Map<String, dynamic> toJson() => {
    'name': name,
    'status': status,
    'matches_used': matchesUsed,
    'notes': notes,
    'timestamp': timestamp?.toUtc().toIso8601String(),
  };

  Future<void> updateBattery(Battery battery) {
    final payload = toJson();
    if (status != null) payload['status'] = battery.status;
    if (matchesUsed != null) payload['matches_used'] = battery.matchesUsed;
    if (notes != null) payload['notes'] = battery.notes;
    payload['timestamp'] = DateTime.now().toUtc().toIso8601String();
    return WebSocketService.instance.sendRequest('UPDATE_BATTERY', payload);
  }

  Future<void> addBattery(Battery battery) {
    final payload = toJson();
    if (status != null) payload['status'] = battery.status;
    if (matchesUsed != null) payload['matches_used'] = battery.matchesUsed;
    if (notes != null) payload['notes'] = battery.notes;
    payload['timestamp'] = DateTime.now().toUtc().toIso8601String();
    return WebSocketService.instance.sendRequest('ADD_BATTERY', payload);
  }

  Future<void> removeBattery() {
    return WebSocketService.instance.sendRequest('REMOVE_BATTERY', {'name': name});
  }

  void changeStatus(String newStatus) {}

  void changeName(String newName) {}

  void changeMatchesUsed(int newAmt) {}
}
