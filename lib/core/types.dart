import 'dart:convert';
import 'package:flutter/material.dart';

class WSMessage {
  String? groupKey;
  DateTime? timestamp;
  String? infoType;
  Map<String, dynamic>? payload;
}

void handleWSPayload(WSMessage message) {
  switch(message.infoType) {
    case "diff":
      
      break;
    case "change":
      // Handle change payload
      break;
    case "query":
      // Handle query payload
      break;
  }
}

class Group {
  String? groupName;
  String? eventKey;
  int? teamNum;
  String? teamAvatarB64;
  String? groupkey;

  Image teamAvatar() {
    return Image.memory(base64Decode(teamAvatarB64!));
  }

  void changeEventKey(String newKey) {

  }
}

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

class LogEntry {
  String? username;
  String? action;
  DateTime? timestamp;
}

class Battery {
  String? name;
  String? status;
  int? matchesUsed;
  String? notes;
  DateTime? timestamp;

  void addBattery() {

  }

  void removeBattery() {

  }

  void changeBatteryStatus() {

  }
}

class Member {
  String? userName;
  String? displayName;
  String? job;
  String? role;
  String? location;
  bool? isAdmin;

  void setJob() {

  }

  void setRole() {

  }

  void setLocation() {

  }

  void removeMember() {

  }

}

class User extends Member {
  void setOwnJob() {

  }

  void setOwnRole() {

  }

  void setOwnLocation() {

  }
}