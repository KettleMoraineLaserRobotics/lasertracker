import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lasertracker/models/models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:lasertracker/core/database.dart';
import 'package:lasertracker/core/layout.dart';
import 'package:url_launcher/url_launcher.dart';

class TeamView extends StatefulWidget {
  const TeamView({super.key});

  @override
  State<TeamView> createState() => _TeamViewState();
}

class _TeamViewState extends State<TeamView> {
  Group get group => getGroup();
  List<EventStream> get streams => getStreams();

  List<Match> get upcomingMatches {
    final upcoming = getMatches().where((match) => match.actualTime == null).toList();
    upcoming.sort((a, b) {
      final at = a.timestamp, bt = b.timestamp;
      if (at == null && bt == null) return 0;
      if (at == null) return 1;
      if (bt == null) return -1;
      return at.compareTo(bt);
    });
    return upcoming;
  }

  List<Member> get driveTeam => getMembers().where((m) => (m.job ?? "").contains("Drive Team")).toList();

  String? selectedStream;

  static const bool useFakeData = bool.fromEnvironment('FAKE_DATA');

  @override
  Widget build(BuildContext context) {
    final wide = isWideScreen(context);

    return wide ? wideLayout(context) : narrowLayout(context);
  }

  Widget wideLayout(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        Hive.box('group').listenable(),
        Hive.box('members').listenable(),
        Hive.box('matches').listenable(),
        Hive.box('streams').listenable(),
      ]),
      builder: (context, child) {
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
                    nextMatchSection(context, upcomingMatches),
                    const SizedBox(height: 16),
                    driveTeamSection(context),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: (1 / 3) * (MediaQuery.sizeOf(context).width),
                child: ListView(children: [upcomingMatchesSection(context, upcomingMatches, wide: true)]),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget narrowLayout(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        Hive.box('group').listenable(),
        Hive.box('members').listenable(),
        Hive.box('matches').listenable(),
      ]),
      builder: (context, child) {
        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            const SizedBox(height: 16),
            header(context, wide: false),
            const SizedBox(height: 24),
            driveTeamSection(context),
            nextMatchSection(context, upcomingMatches),
            upcomingMatchesSection(context, upcomingMatches, wide: false),
          ],
        );
      },
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
        SizedBox(height: 40, child: group.teamAvatar()),
        const SizedBox(width: 16),
        if (wide)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${group.groupName} | Team ${group.teamNum}",
                  style: titleLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                InkWell(
                  borderRadius: BorderRadius.circular(12),

                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text("Group Key: ", style: Theme.of(context).textTheme.titleSmall),
                        Text(group.groupkey ?? '', style: GoogleFonts.notoSansMono()),
                      ],
                    ),
                  ),
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: group.groupkey!));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Copied group key to clipboard!"),
                        behavior: SnackBarBehavior.floating,
                        margin: EdgeInsets.all(16),
                      ),
                    );
                  },
                ),
                if (useFakeData)
                  Text(
                    "Testing mode is on. Fake data will be used.",
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.error),
                  ),
              ],
            ),
          )
        else ...[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("${group.groupName}", style: titleLarge, maxLines: 1, overflow: TextOverflow.ellipsis),
                Text("Team ${group.teamNum}", style: Theme.of(context).textTheme.titleMedium),
                if (useFakeData)
                  Text(
                    "Testing mode is on.",
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.error),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          InkWell(
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: EdgeInsets.all(8),
              child: Column(
                children: [
                  Text("Group Key", style: titleLarge),
                  Text(group.groupkey ?? "", style: GoogleFonts.notoSansMono()),
                ],
              ),
            ),
            onTap: () {
              Clipboard.setData(ClipboardData(text: group.groupkey!));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Copied group key to clipboard!"),
                  behavior: SnackBarBehavior.floating,
                  margin: EdgeInsets.all(16),
                ),
              );
            },
          ),
        ],
      ],
    );
  }

  Widget streamPlayer() {
    final streams = this.streams;
    if (streams.isEmpty) {
      return Center(child: Text("No streams found for this event.", style: Theme.of(context).textTheme.bodyLarge));
    }

    final current = streams.firstWhere((stream) => stream.url == selectedStream, orElse: () => streams.first);
    final canEmbed = current.url?.startsWith("https://") ?? false;
    final embedUrl = twitchParentFix(current.url ?? "");

    return Column(
      children: [
        if (streams.length > 1)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                for (final stream in streams)
                  ChoiceChip(
                    label: Text(stream.name ?? "Unnamed Stream"),
                    selected: stream.url == current.url,
                    onSelected: (_) => setState(() => selectedStream = stream.url),
                  ),
              ],
            ),
          ),
        Expanded(
          child: canEmbed
              ? HtmlWidget(
                  key: ValueKey(embedUrl),
                  """<iframe width="100%" height="100%" src="$embedUrl" title="${current.name}" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe>""",
                )
              : Center(child: Text("This stream can't be embedded.", style: Theme.of(context).textTheme.bodyLarge)),
        ),
      ],
    );
  }

  String twitchParentFix(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || uri.host != "player.twitch.tv" || Uri.base.host.isEmpty) return url;
    return uri.replace(queryParameters: {...uri.queryParameters, "parent": Uri.base.host}).toString();
  }

  Widget nextMatchSection(BuildContext context, List<Match> matches) {
    if (matches.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text("No Upcoming Matches", style: Theme.of(context).textTheme.bodyLarge),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text("Next Match", style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 4),
        const Divider(),
        const SizedBox(height: 4),
        MatchRow(match: matches[0], teamNum: group.teamNum),
      ],
    );
  }

  Widget upcomingMatchesSection(BuildContext context, List<Match> matches, {required bool wide}) {
    if (matches.length <= 1) return const SizedBox.shrink();

    final textTheme = Theme.of(context).textTheme;
    final teamNum = group.teamNum;

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
    final driveTeam = this.driveTeam;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text("Drive Team", style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 4),
        const Divider(),
        const SizedBox(height: 4),
        driveTeam.isEmpty
            ? Text("No drive team members", style: Theme.of(context).textTheme.bodyLarge)
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
                                    Text(
                                      member.displayName ?? member.userName ?? "",
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context).textTheme.titleLarge,
                                    ),
                                    Text(
                                      (member.job ?? "").replaceAll("Drive Team - ", ""),
                                      textAlign: TextAlign.center,
                                    ),
                                    Text(member.location ?? "", style: Theme.of(context).textTheme.bodySmall),
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
}

class MatchRow extends StatelessWidget {
  final Match match;
  final int? teamNum;

  const MatchRow({super.key, required this.match, required this.teamNum});

  String get timeStr {
    final dt = match.timestamp;
    if (dt == null) return "TBD";
    return "${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: InkWell(
        onTap: () => launchUrl(Uri.parse("https://www.thebluealliance.com/match/${match.matchKey}")),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AllianceBox(
                label: "Red Alliance",
                color: Colors.red,
                teams: [match.red1, match.red2, match.red3].whereType<int>().toList(),
                teamNum: teamNum,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    Text(
                      match.getMatchName(),
                      style: Theme.of(context).textTheme.titleSmall,
                      textAlign: TextAlign.center,
                    ),
                    Text("VS", style: Theme.of(context).textTheme.labelMedium),
                    Text(timeStr, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              AllianceBox(
                label: "Blue Alliance",
                color: Colors.blue,
                teams: [match.blue1, match.blue2, match.blue3].whereType<int>().toList(),
                teamNum: teamNum,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AllianceBox extends StatelessWidget {
  final String label;
  final Color color;
  final List<int> teams;
  final int? teamNum;

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
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(color: color, fontWeight: isOurs ? FontWeight.w700 : null),
        ),
        Text(teams.join(" "), textAlign: TextAlign.center),
      ],
    );

    if (!isOurs) return Expanded(child: content);

    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: color),
          color: color.withAlpha(25),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Padding(padding: const EdgeInsets.all(5), child: content),
      ),
    );
  }
}
