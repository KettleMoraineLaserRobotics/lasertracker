part of 'models.dart';

class WSMessage {
  String? groupKey;
  DateTime? timestamp;
  String? infoType;
  Map<String, dynamic>? payload;
  String? requestId;

  WSMessage();

  factory WSMessage.fromJson(Map<String, dynamic> json) => WSMessage()
    ..groupKey = json['group_key'] as String?
    ..timestamp = _parseTime(json['timestamp'])
    ..infoType = json['info_type'] as String?
    ..payload = json['payload'] is Map ? Map<String, dynamic>.from(json['payload'] as Map) : null
    ..requestId = json['request_id'] as String?;
}
