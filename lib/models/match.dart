part of 'models.dart';

class Match {
  int? red1;
  int? red2;
  int? red3;
  int? blue1;
  int? blue2;
  int? blue3;
  int? matchNum;
  String? matchKey;
  String? eventKey;
  /*
  Having the event key may seem redundant, but allowd the app to be able
  to seperate matches by an event, since groups are able to switch events.
  Most useful at something like worlds where your matches on Newton are kept
  seperate from your matches on Einstien. Idk, it was the best way to do 
  that that I could think of.
  */
  String? compLevel;
  int? setNumber;
  DateTime? predictedTime;
  DateTime? actualTime;

  DateTime? get timestamp => actualTime ?? predictedTime;

  Match();

  factory Match.fromJson(Map<String, dynamic> json) => Match()
    ..red1 = _asInt(json['red1'])
    ..red2 = _asInt(json['red2'])
    ..red3 = _asInt(json['red3'])
    ..blue1 = _asInt(json['blue1'])
    ..blue2 = _asInt(json['blue2'])
    ..blue3 = _asInt(json['blue3'])
    ..matchNum = _asInt(json['match_num'])
    ..matchKey = json['match_key'] as String?
    ..eventKey = json['event_key'] as String?
    ..compLevel = json['comp_level'] as String?
    ..setNumber = _asInt(json['set_number'])
    ..predictedTime = _parseTime(json['predicted_time'])
    ..actualTime = _parseTime(json['actual_time']);

  Map<String, dynamic> toJson() => {
    'red1': red1,
    'red2': red2,
    'red3': red3,
    'blue1': blue1,
    'blue2': blue2,
    'blue3': blue3,
    'match_num': matchNum,
    'match_key': matchKey,
    'event_key': eventKey,
    'comp_level': compLevel,
    'set_number': setNumber,
    'predicted_time': predictedTime?.toUtc().toIso8601String(),
    'actual_time': actualTime?.toUtc().toIso8601String(),
  };

  String getMatchName() {
    final matchCode = (matchKey ?? "").replaceAll("${eventKey}_", "");

    if (matchCode.startsWith("qm")) {
      return "Quals ${matchCode.replaceFirst("qm", "")}";
    }

    if (matchCode.startsWith("sf")) {
      final sfMatch = RegExp(r'^sf(\d+)m(\d+)$').firstMatch(matchCode);
      if (sfMatch == null) {
        return "Playoffs ${matchCode.replaceFirst("sf", "")}";
      }

      int bracketMatchNumber = int.parse(sfMatch.group(1)!);
      String roundName = switch (bracketMatchNumber) {
        1 || 2 || 3 || 4 => "Upper Round 1",
        5 || 6 => "Lower Round 1",
        7 || 8 => "Upper Round 2",
        9 || 10 => "Lower Round 2",
        11 => "Lower Round 3",
        12 => "Upper Round 3",
        13 => "Lower Finals",
        _ => "Playoffs",
      };
      return "$roundName\n(Match $bracketMatchNumber)";
    }

    if (matchCode.startsWith("f")) {
      final fMatch = RegExp(r'^f\d+m(\d+)$').firstMatch(matchCode);
      if (fMatch != null) {
        return "Finals Match ${fMatch.group(1)}";
      }
      return "Finals ${matchCode.replaceFirst("f", "")}";
    }

    return "Unknown";
  }
}
