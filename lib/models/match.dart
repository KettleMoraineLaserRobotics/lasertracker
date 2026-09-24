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
  DateTime? timestamp;

  Future getMatchName() async {
    String matchCode = matchKey!.replaceAll("{$eventKey!}_", "");
    String matchName = "Unknown";

    if (matchCode.startsWith("qm")) {
      matchName = "Quals ${matchCode.replaceFirst("qm", "")}";
    } else if (matchCode.startsWith("sf")) {
      final sfMatch = RegExp(r'^sf(\d+)m(\d+)$').firstMatch(matchCode);

      if (sfMatch != null) {
        int bracketMatchNumber = int.parse(sfMatch.group(1)!);
        String roundName;

        switch (bracketMatchNumber) {
          case 4:
            roundName = "Upper Round 1";
            break;
          case 6:
            roundName = "Lower Round 1";
            break;
          case 8:
            roundName = "Upper Round 2";
            break;
          case 10:
            roundName = "Lower Round 2";
            break;
          case 11:
            roundName = "Lower Round 3";
            break;
          case 12:
            roundName = "Upper Round 3";
            break;
          case 13:
            roundName = "Lower Finals";
            break;
          default:
            roundName = "Playoffs";
        }

        matchName = "$roundName\n(Match $bracketMatchNumber)";
      } else {
        matchName = "Playoffs ${matchCode.replaceFirst("sf", "")}";
      }
    } else if (matchCode.startsWith("f")) {
      final fMatch = RegExp(r'^f\d+m(\d+)$').firstMatch(matchCode);

      if (fMatch != null) {
        matchName = "Finals Match ${fMatch.group(1)}";
      } else {
        matchName = "Finals ${matchCode.replaceFirst("f", "")}";
      }
    }
    return matchName;
  }
}