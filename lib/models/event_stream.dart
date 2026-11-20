part of 'models.dart';

class EventStream {
  String? name;
  String? url;
  String? date;
  String? type;

  EventStream();

  factory EventStream.fromJson(Map<String, dynamic> json) => EventStream()
    ..name = json['name'] as String?
    ..url = json['url'] as String?
    ..date = json['date'] as String?
    ..type = json['type'] as String?;

  Map<String, dynamic> toJson() => {'name': name, 'url': url, 'date': date, 'type': type};
}
