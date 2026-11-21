import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:lasertracker/core/database.dart';
import 'package:lasertracker/core/layout.dart';
import 'package:lasertracker/models/models.dart';
import 'package:lasertracker/widgets/error_snack.dart';

class BatteriesView extends StatefulWidget {
  const BatteriesView({super.key});

  @override
  State<BatteriesView> createState() => _BatteriesViewState();
}

class _BatteriesViewState extends State<BatteriesView> {
  static const List<String> statuses = ["In Robot", "Charging", "Charged", "Resting", "Dead"];

  Map<String, List<Battery>> get batteriesByStatus {
    final Map<String, List<Battery>> groups = {};
    for (final battery in getBatteries()) {
      groups.putIfAbsent(battery.status ?? "Unknown", () => []).add(battery);
    }
    for (final list in groups.values) {
      list.sort((a, b) => (a.name ?? "").compareTo(b.name ?? ""));
    }
    int rank(String s) {
      final i = statuses.indexOf(s);
      return i == -1 ? statuses.length : i;
    }

    final keys = groups.keys.toList()..sort((a, b) => rank(a).compareTo(rank(b)));
    return {for (final k in keys) k: groups[k]!};
  }

  final ScrollController statusScrollController = ScrollController();

  List<DropdownMenuEntry<String>> listToEntries(List<String> list) {
    return list.map((item) => DropdownMenuEntry(value: item, label: item)).toList();
  }

  @override
  void dispose() {
    statusScrollController.dispose();
    super.dispose();
  }

  Future<bool?> showEditDialog(
    BuildContext context,
    ScaffoldMessengerState scaffoldMessenger,
    Battery battery,
    bool isNew,
  ) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        final TextEditingController nameController = TextEditingController();
        final TextEditingController statusController = TextEditingController(text: battery.status ?? "");
        final TextEditingController notesController = TextEditingController(text: battery.notes ?? "");
        int matchesUsed = battery.matchesUsed ?? 0;

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      "${isNew ? "Add" : "Edit"} ${battery.name ?? "Battery"}",
                      style: Theme.of(context).textTheme.displaySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  isNew
                      ? SizedBox.shrink()
                      : ElevatedButton(
                          onPressed: () async {
                            final navigator = Navigator.of(context);
                            try {
                              await battery.removeBattery();
                              scaffoldMessenger.showSnackBar(
                                const SnackBar(
                                  content: Text("Battery removed successfully!"),
                                  behavior: SnackBarBehavior.floating,
                                  margin: EdgeInsets.all(16),
                                ),
                              );
                              navigator.pop(true);
                            } catch (e) {
                              ErrorSnack.showErrorSnackBar(scaffoldMessenger, e);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.error,
                            foregroundColor: Theme.of(context).colorScheme.onError,
                          ),
                          child: const Text('Remove'),
                        ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    isNew
                        ? TextField(
                            controller: nameController,
                            decoration: const InputDecoration(labelText: "Name", border: OutlineInputBorder()),
                          )
                        : SizedBox.shrink(),
                    SizedBox(height: 16),
                    DropdownMenu<String>(
                      expandedInsets: EdgeInsets.zero,
                      controller: statusController,
                      label: Text("Status", style: Theme.of(context).textTheme.titleSmall),
                      inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
                      initialSelection: battery.status,
                      dropdownMenuEntries: listToEntries(statuses),
                      onSelected: (value) {
                        statusController.text = value ?? "";
                      },
                    ),
                    const SizedBox(height: 16),
                    Text("Matches Used", style: Theme.of(context).textTheme.titleSmall),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          onPressed: matchesUsed > 0 ? () => setState(() => matchesUsed--) : null,
                          icon: const Icon(Icons.remove),
                        ),
                        Text(matchesUsed.toString(), style: Theme.of(context).textTheme.titleMedium),
                        IconButton(onPressed: () => setState(() => matchesUsed++), icon: const Icon(Icons.add)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: notesController,
                      minLines: 3,
                      maxLines: 5,
                      decoration: const InputDecoration(labelText: "Notes", border: OutlineInputBorder()),
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      onPressed: () async {
                        final navigator = Navigator.of(context);
                        try {
                          if (isNew) {
                            battery.name = nameController.text;
                          }
                          battery.status = statusController.text;
                          battery.notes = notesController.text;
                          battery.matchesUsed = matchesUsed;
                          if (isNew) {
                            await battery.addBattery(battery);
                            scaffoldMessenger.showSnackBar(
                              const SnackBar(
                                content: Text("Battery added successfully!"),
                                behavior: SnackBarBehavior.floating,
                                margin: EdgeInsets.all(16),
                              ),
                            );
                          } else {
                            await battery.updateBattery(battery);
                            scaffoldMessenger.showSnackBar(
                              const SnackBar(
                                content: Text("Battery updated successfully!"),
                                behavior: SnackBarBehavior.floating,
                                margin: EdgeInsets.all(16),
                              ),
                            );
                          }

                          navigator.pop(true);
                        } catch (e) {
                          ErrorSnack.showErrorSnackBar(scaffoldMessenger, e);
                        }
                      },
                      child: const Text('Save'),
                    ),
                    SizedBox(width: 8),
                    ElevatedButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Hive.box('batteries').listenable(),
      builder: (context, child) {
        final scaffoldMessenger = ScaffoldMessenger.of(context);
        final wide = isWideScreen(context);

        return Column(
          children: [
            Expanded(
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  const SizedBox(height: 16),
                  Text("Batteries", style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
                  SizedBox(height: wide ? 16 : 5),
                  batteriesSection(context, scaffoldMessenger, wide: wide),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Spacer(),
                  FloatingActionButton(
                    child: const Icon(Icons.add),
                    onPressed: () {
                      Battery newBattery = Battery();
                      showEditDialog(context, scaffoldMessenger, newBattery, true);
                    },
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget batteriesSection(BuildContext context, ScaffoldMessengerState scaffoldMessenger, {required bool wide}) {
    final groups = batteriesByStatus;
    if (groups.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text("No Batteries", style: Theme.of(context).textTheme.bodyLarge),
        ),
      );
    }

    final statusTables = groups.entries
        .map((entry) => statusTable(context, entry.key, entry.value, scaffoldMessenger, wide))
        .toList();

    if (!wide) return Column(children: statusTables);

    return Scrollbar(
      controller: statusScrollController,
      thumbVisibility: true,
      child: SingleChildScrollView(
        controller: statusScrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: statusTables
              .map(
                (table) => SizedBox(
                  width: 420,
                  child: Padding(padding: const EdgeInsets.only(right: 16, bottom: 16), child: table),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  Widget statusTable(
    BuildContext context,
    String status,
    List<Battery> list,
    ScaffoldMessengerState scaffoldMessenger,
    bool wide,
  ) {
    final textTheme = Theme.of(context).textTheme;
    final headerStyle = wide ? textTheme.titleMedium : textTheme.titleSmall;

    Widget cell(String text, TextStyle? style) => Expanded(
      child: Text(text, textAlign: TextAlign.center, style: style),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!wide) const SizedBox(height: 10),
        Text(status, style: wide ? textTheme.titleMedium : textTheme.titleLarge, textAlign: TextAlign.center),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [cell("Name", headerStyle), cell("Matches Used", headerStyle), cell("Last Updated", headerStyle)],
          ),
        ),
        ...list.map<Widget>((battery) {
          final name = battery.name ?? "";

          final row = Row(
            children: [
              cell(name, textTheme.titleSmall),
              cell((battery.matchesUsed ?? 0).toString(), textTheme.titleSmall),
              cell(battery.timestamp!.toLocal().toString(), textTheme.titleSmall),
            ],
          );

          return Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Tooltip(
              message: "Edit $name",
              child: Material(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                clipBehavior: Clip.antiAlias,
                color: Theme.of(context).colorScheme.primaryContainer,
                child: InkWell(
                  mouseCursor: SystemMouseCursors.click,
                  onTap: () => showEditDialog(context, scaffoldMessenger, battery, false),
                  child: Padding(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14), child: row),
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 16),
      ],
    );
  }
}
