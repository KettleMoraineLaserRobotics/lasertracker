import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:lasertracker/core/api.dart';
import 'package:lasertracker/core/layout.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TeamView extends StatefulWidget {
  const TeamView({super.key});

  @override
  State<TeamView> createState() => _TeamViewState();
}

class _TeamViewState extends State<TeamView> {
  String teamNum = "";
  String groupName = "";
  String eventKey = "";
  String groupKey = "";
  List<dynamic> availableStreams = [];
  String? selectedStreamId;
  bool isLoadingStream = true;

  Future<Image>? avatarFuture;
  Future<List<dynamic>>? matchesFuture;
  Future<List<dynamic>>? membersFuture;

  Timer? refreshTimer;

  static const bool useFakeData = bool.fromEnvironment('FAKE_DATA');

  @override
  void initState() {
    super.initState();
    loadData();

    refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        silentRefresh();
      }
    });
  }

  @override
  void dispose() {
    refreshTimer?.cancel();
    super.dispose();
  }

  void loadData() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      teamNum = prefs.getString("team_number") ?? "";
      groupName = prefs.getString("group_name") ?? "";
      eventKey = prefs.getString("event_key") ?? "";
      groupKey = prefs.getString("loginGroupKey") ?? "";

      if (teamNum.isNotEmpty) {
        avatarFuture = getTeamAvatar(teamNum);
        membersFuture = getMembers();
        if (eventKey.isNotEmpty) {
          matchesFuture = getMatches(teamNum, eventKey);
        }
      }
    });

    loadStreams();
  }

  Future<void> loadStreams() async {
    List<dynamic> streams;
    try {
      streams = await getStream();
    } catch (_) {
      streams = [];
    }
    if (!mounted) return;

    setState(() {
      availableStreams = streams;
      if (streams.isEmpty) {
        selectedStreamId = null;
      } else if (selectedStreamId == null || !streams.any((s) => s["video_id"] == selectedStreamId)) {
        selectedStreamId = streams[0]["video_id"];
      }
      isLoadingStream = false;
    });
  }

  Future<void> silentRefresh() async {
    if (teamNum.isEmpty) return;

    setState(() {
      membersFuture = getMembers();
      if (eventKey.isNotEmpty) {
        matchesFuture = getMatches(teamNum, eventKey);
      }
    });

    loadStreams();
  }

  @override
  Widget build(BuildContext context) {
    if (teamNum.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final wide = isWideScreen(context);

    return RefreshIndicator(
      onRefresh: () async {
        silentRefresh();
        await Future.delayed(const Duration(milliseconds: 500));
      },
      child: wide ? wideLayout(context) : narrowLayout(context),
    );
  }

  Widget wideLayout(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                header(context, wide: true),
                const SizedBox(height: 16),
                SizedBox(height: (1 / 2) * (MediaQuery.sizeOf(context).height), child: streamPlayer()),
                const SizedBox(height: 16),
                matchesBuilder((matches) => nextMatchSection(context, matches)),
                const SizedBox(height: 16),
                driveTeamSection(context),
              ],
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: (1 / 3) * (MediaQuery.sizeOf(context).width),
            child: ListView(
              children: [matchesBuilder((matches) => upcomingMatchesSection(context, matches, wide: true))],
            ),
          ),
        ],
      ),
    );
  }

  Widget narrowLayout(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        const SizedBox(height: 16),
        header(context, wide: false),
        const SizedBox(height: 24),
        driveTeamSection(context),
        matchesBuilder((matches) => nextMatchSection(context, matches)),
        matchesBuilder((matches) => upcomingMatchesSection(context, matches, wide: false)),
      ],
    );
  }

  Widget spinner() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator()),
      ),
    );
  }

  Widget header(BuildContext context, {required bool wide}) {
    final titleLarge = Theme.of(context).textTheme.titleLarge;

    return Row(
      children: [
        SizedBox(
          height: 40,
          child: FutureBuilder<Image>(
            future: avatarFuture,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Center(child: Text("Error fetching team avatar"));
              }
              if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
                return snapshot.data!;
              }
              return spinner();
            },
          ),
        ),
        const SizedBox(width: 16),
        if (wide)
          Column(children: [
            Text("$groupName | Team $teamNum", style: titleLarge),
            if (useFakeData) const Text("Testing mode is on. Fake data will be used.", style: TextStyle(color: Colors.red)),
          ],)
        else ...[
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(groupName, style: titleLarge),
              Text("Team $teamNum"),
              if (useFakeData) const Text("Testing mode is on.", style: TextStyle(color: Colors.red)),
            ],
          ),
          const Spacer(),
          Column(
            children: [
              Text("Join Key", style: titleLarge),
              Text(groupKey),
            ],
          ),
        ],
      ],
    );
  }

  Widget streamPlayer() {
    if (isLoadingStream) {
      return const Center(child: CircularProgressIndicator());
    }
    if (availableStreams.isEmpty || selectedStreamId == null) {
      return const Center(child: Text("No YouTube streams available for this event."));
    }
    return Column(
      children: [
        if (availableStreams.length > 1)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: DropdownButton<String>(
              value: selectedStreamId,
              isExpanded: true,
              items: availableStreams.map((stream) {
                return DropdownMenuItem<String>(
                  value: stream["video_id"],
                  child: Text(stream["name"] ?? "Unnamed Stream"),
                );
              }).toList(),
              onChanged: (newId) {
                if (newId != null) {
                  setState(() {
                    selectedStreamId = newId;
                  });
                }
              },
            ),
          ),
        Expanded(
          child: HtmlWidget(
            key: ValueKey(selectedStreamId),
            """<iframe width="100%" height="100%" src="https://www.youtube.com/embed/$selectedStreamId" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe>""",
          ),
        ),
      ],
    );
  }

  Widget matchesBuilder(Widget Function(List<UpcomingMatch> matches) builder) {
    return FutureBuilder(
      future: matchesFuture,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return builder(parseUpcomingMatches(snapshot.data as List<dynamic>, eventKey));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return spinner();
        }
        if (snapshot.hasError) {
          return const Center(child: Text("Error fetching matches"));
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget nextMatchSection(BuildContext context, List<UpcomingMatch> matches) {
    if (matches.isEmpty) {
      return const Center(
        child: Padding(padding: EdgeInsets.all(16), child: Text("No Upcoming Matches")),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text("Next Match", style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 4),
        const Divider(),
        const SizedBox(height: 4),
        MatchRow(match: matches[0], teamNum: teamNum),
      ],
    );
  }

  Widget upcomingMatchesSection(BuildContext context, List<UpcomingMatch> matches, {required bool wide}) {
    if (matches.length <= 1) return const SizedBox.shrink();

    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 24, bottom: 8),
          child: Text("Upcoming Matches", style: wide ? textTheme.titleLarge : textTheme.titleMedium),
        ),
        for (final upcomingMatch in matches.skip(1))
          Column(
            children: [
              const SizedBox(height: 5),
              const Divider(),
              const SizedBox(height: 5),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: MatchRow(match: upcomingMatch, teamNum: teamNum),
              ),
            ],
          ),
      ],
    );
  }

  Widget driveTeamSection(BuildContext context) {
    return FutureBuilder(
      future: membersFuture,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final data = snapshot.data as List<dynamic>;
          List<dynamic> driveTeam = [];

          for (var member in data) {
            if (member["job"].toString().contains("Drive Team")) {
              driveTeam.add(member);
            }
          }

          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Drive Team", style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              const Divider(),
              const SizedBox(height: 4),
              driveTeam.isEmpty
                  ? const Text("No drive team members")
                  : SizedBox(
                      height: 80,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(minWidth: constraints.maxWidth),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  for (final member in driveTeam)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 8),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          Text(member["display_name"], textAlign: TextAlign.center, style: TextStyle(fontSize: 22),),
                                          Text(
                                            member["job"].toString().replaceAll("Drive Team - ", ""),
                                            textAlign: TextAlign.center,
                                          ),
                                          Text(member["location"]),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
            ],
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return spinner();
        }
        if (snapshot.hasError) {
          return const Center(child: Text("Error fetching members"));
        }

        return const SizedBox.shrink();
      },
    );
  }
}

class UpcomingMatch {
  final String name;
  final String time;
  final List<String> redTeams;
  final List<String> blueTeams;

  const UpcomingMatch(this.name, this.time, this.redTeams, this.blueTeams);
}

List<UpcomingMatch> parseUpcomingMatches(List<dynamic> data, String eventKey) {
  List<UpcomingMatch> matches = [];

  for (var match in data) {
    if (match["actual_time"] != null) continue;

    String matchKey = match["key"].toString().replaceAll("${eventKey}_", "");

    List<String> redTeams = (match["alliances"]["red"]["team_keys"] as List)
        .map((team) => team.toString().replaceAll("frc", ""))
        .toList();

    List<String> blueTeams = (match["alliances"]["blue"]["team_keys"] as List)
        .map((team) => team.toString().replaceAll("frc", ""))
        .toList();

    int? timestamp = match["predicted_time"] ?? match["time"];
    String timeStr = "TBD";

    if (timestamp != null) {
      DateTime dt = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
      timeStr = "${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";
    }

    matches.add(UpcomingMatch(matchName(matchKey), timeStr, redTeams, blueTeams));
  }

  return matches;
}

String matchName(String matchKey) {
  if (matchKey.startsWith("qm")) {
    return "Quals ${matchKey.replaceFirst("qm", "")}";
  }

  if (matchKey.startsWith("sf")) {
    final sfMatch = RegExp(r'^sf(\d+)m(\d+)$').firstMatch(matchKey);
    if (sfMatch == null) {
      return "Playoffs ${matchKey.replaceFirst("sf", "")}";
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

  if (matchKey.startsWith("f")) {
    final fMatch = RegExp(r'^f\d+m(\d+)$').firstMatch(matchKey);
    if (fMatch != null) {
      return "Finals Match ${fMatch.group(1)}";
    }
    return "Finals ${matchKey.replaceFirst("f", "")}";
  }

  return "Unknown";
}

class MatchRow extends StatelessWidget {
  final UpcomingMatch match;
  final String teamNum;

  const MatchRow({super.key, required this.match, required this.teamNum});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AllianceBox(label: "Red Alliance", color: Colors.red, teams: match.redTeams, teamNum: teamNum),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              Text(
                match.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const Text("VS"),
              Text(match.time),
            ],
          ),
        ),
        AllianceBox(label: "Blue Alliance", color: Colors.blue, teams: match.blueTeams, teamNum: teamNum),
      ],
    );
  }
}

class AllianceBox extends StatelessWidget {
  final String label;
  final Color color;
  final List<String> teams;
  final String teamNum;

  const AllianceBox({super.key, required this.label, required this.color, required this.teams, required this.teamNum});

  @override
  Widget build(BuildContext context) {
    final isOurs = teams.contains(teamNum);

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(color: color, fontWeight: isOurs ? FontWeight.bold : null),
        ),
        Text(teams.join(" "), textAlign: TextAlign.center),
      ],
    );

    if (!isOurs) return Expanded(child: content);

    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: color),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Padding(padding: const EdgeInsets.all(5), child: content),
      ),
    );
  }
}
