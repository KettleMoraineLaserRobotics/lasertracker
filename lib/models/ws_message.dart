part of 'models.dart';

class WSMessage {
  String? groupKey;
  DateTime? timestamp;
  String? infoType;
  List<Map<String, dynamic>>? payload;
}