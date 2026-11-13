import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lasertracker/core/api.dart';
import 'package:lasertracker/core/layout.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MembersView extends StatefulWidget {
  const MembersView({super.key});

  @override
  State<MembersView> createState() => _MembersViewState();
}

class _MembersViewState extends State<MembersView> {
  List<String> locations = [
    "Cafeteria",
    "Stands",
    "Pits",
    "Impact Award room",
    "Leadership Award room",
    "Woodie Flowers Award room",
    "Queuing/Field",
    "At Home",
    "Quiet Room",
    "Custom",
  ];

  List<String> jobs = [
    "Safety Captain",
    "Drive Team - Drive Coach",
    "Drive Team - Driver",
    "Drive Team - Tech Driver",
    "Drive Team - Technician",
    "Impact Award Presenter",
    "Student Ambassador",
    "Custom",
  ];

  List<String> roles = ["Student", "Mentor", "Lead Coach 1", "Lead Coach 2"];

  String currLoc = "";
  String currJob = "";
  String currRole = "";
  String loggedInUsername = "";
  bool userIsAdmin = false;
  Future<List<dynamic>>? membersFuture;
  Future<bool>? isAdminFuture;

  Timer? refreshTimer;
  final ScrollController locationScrollController = ScrollController();

  final TextEditingController locationController = TextEditingController();
  final TextEditingController jobController = TextEditingController();
  final TextEditingController roleController = TextEditingController();
  final TextEditingController customJobController = TextEditingController();
  final TextEditingController customLocationController = TextEditingController();
  final TextEditingController newPinController = TextEditingController();

  List<DropdownMenuEntry> listToEntries(List list) {
    List<DropdownMenuEntry> entries = [];
    for (var item in list) {
      var entry = DropdownMenuEntry(value: item, label: item);
      entries.add(entry);
    }
    return entries;
  }

  void loadData() async {
    membersFuture = getMembers();
    isAdminFuture = isAdmin();
    final prefs = await SharedPreferences.getInstance();
    userIsAdmin = await isAdmin();

    setState(() {
      currLoc = prefs.getString("location") ?? "";
      currJob = prefs.getString("job") ?? "";
      currRole = prefs.getString("role") ?? "";
      loggedInUsername = prefs.getString("loginUsername") ?? "";
      locationController.text = currLoc;
      jobController.text = currJob;
      userIsAdmin = userIsAdmin;
    });
  }

  @override
  void dispose() {
    locationController.dispose();
    jobController.dispose();
    roleController.dispose();
    customJobController.dispose();
    customLocationController.dispose();
    newPinController.dispose();
    refreshTimer?.cancel();
    locationScrollController.dispose();
    super.dispose();
  }

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

  Future<void> silentRefresh() async {
    setState(() {
      membersFuture = getMembers();
      isAdminFuture = isAdmin();
    });
  }

  void showError(ScaffoldMessengerState scaffoldMessenger, Object e) {
    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text("Error: ${e.toString()}"),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<bool?> showEditDialog(
    BuildContext context,
    String role,
    ScaffoldMessengerState scaffoldMessenger,
    var memberData,
  ) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        final TextEditingController memberRoleController = TextEditingController(text: role);
        bool isAdmin;
        if (memberData["is_admin"] == 1) {
          isAdmin = true;
        } else {
          isAdmin = false;
        }
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: const Text("Edit Member"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownMenu(
                      expandedInsets: EdgeInsets.zero,
                      controller: memberRoleController,
                      label: Text("Role", style: Theme.of(context).textTheme.titleSmall),
                      inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
                      initialSelection: role,
                      enabled: userIsAdmin && (memberData["username"] != loggedInUsername),
                      dropdownMenuEntries: listToEntries(roles),
                      onSelected: (value) {
                        memberRoleController.text = value ?? "";
                      },
                    ),
                    const SizedBox(height: 16),
                    CheckboxListTile(
                      title: const Text("User is admin"),
                      value: isAdmin,
                      onChanged: (bool? newValue) {
                        if (newValue == null) return;
                        setState(() {
                          isAdmin = newValue;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: newPinController,
                      decoration: const InputDecoration(labelText: "New Pin (Optional)", border: OutlineInputBorder()),
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                ElevatedButton(
                  onPressed: () async {
                    try {
                      if (newPinController.text != "") {
                        await changePin(memberData["username"], newPinController.text);
                        newPinController.text = "";
                      }
                      await changeRole(memberData["username"], memberRoleController.text);
                      await changeAdmin(memberData["username"], isAdmin);
                      scaffoldMessenger.showSnackBar(const SnackBar(content: Text("Member updated successfully!")));
                      if (context.mounted) {
                        Navigator.pop(context, true);
                      }
                    } catch (e) {
                      showError(scaffoldMessenger, e);
                    }
                  },
                  child: const Text('Save'),
                ),
                ElevatedButton(
                  onPressed: () {
                    newPinController.text = "";
                    Navigator.pop(context, false);
                  },
                  child: const Text('Cancel'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget statusDropdown({
    required String label,
    required String prefsKey,
    required String customTitle,
    required String customLabel,
    required String customButton,
    required TextEditingController controller,
    required TextEditingController customController,
    required String current,
    required List<String> options,
    required ScaffoldMessengerState scaffoldMessenger,
  }) {
    return DropdownMenu(
      controller: controller,
      expandedInsets: EdgeInsets.zero,
      label: Text(label),
      inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
      onSelected: (value) async {
        try {
          if (value == "Custom") {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Text(customTitle),
                  content: TextField(
                    controller: customController,
                    decoration: InputDecoration(labelText: customLabel, border: const OutlineInputBorder()),
                  ),
                  actions: <Widget>[
                    ElevatedButton(
                      onPressed: () async {
                        try {
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setString(prefsKey, customController.text);
                          await setStatus();
                          controller.text = customController.text;
                          if (context.mounted) Navigator.pop(context);
                        } catch (e) {
                          showError(scaffoldMessenger, e);
                        }
                      },
                      child: Text(customButton),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        controller.text = current;
                        Navigator.pop(context);
                      },
                      child: const Text('Cancel'),
                    ),
                  ],
                );
              },
            );
          } else {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString(prefsKey, value.toString());
            await setStatus();
          }
        } catch (e) {
          showError(scaffoldMessenger, e);
        }
      },
      initialSelection: current,
      dropdownMenuEntries: listToEntries(options),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final wide = isWideScreen(context);

    final statusFields = <Widget>[
      statusDropdown(
        label: "Location",
        prefsKey: "location",
        customTitle: "Custom Location",
        customLabel: "Location",
        customButton: "Set Location",
        controller: locationController,
        customController: customLocationController,
        current: currLoc,
        options: locations,
        scaffoldMessenger: scaffoldMessenger,
      ),
      statusDropdown(
        label: "Job",
        prefsKey: "job",
        customTitle: "Custom Job",
        customLabel: "Job Title",
        customButton: "Set Job",
        controller: jobController,
        customController: customJobController,
        current: currJob,
        options: jobs,
        scaffoldMessenger: scaffoldMessenger,
      ),
      DropdownMenu(
        expandedInsets: EdgeInsets.zero,
        controller: roleController,
        label: const Text("Role"),
        inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
        enabled: false,
        initialSelection: currRole,
        onSelected: (value) async {
          try {
            await changeRole(loggedInUsername, value ?? "");
          } on Exception catch (e) {
            showError(scaffoldMessenger, e);
          }
        },
        dropdownMenuEntries: listToEntries(roles),
      ),
    ];

    return RefreshIndicator(
      onRefresh: () async {
        silentRefresh();
        await Future.delayed(const Duration(milliseconds: 500));
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          const SizedBox(height: 16),
          Text("Your Status", style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
          const SizedBox(height: 5),
          wide
              ? Row(
                  children: [
                    for (var i = 0; i < statusFields.length; i++) ...[
                      if (i > 0) const SizedBox(width: 16),
                      Expanded(child: statusFields[i]),
                    ],
                  ],
                )
              : Column(
                  children: [
                    for (var i = 0; i < statusFields.length; i++) ...[
                      if (i > 0) const SizedBox(height: 16),
                      statusFields[i],
                    ],
                  ],
                ),
          const SizedBox(height: 16),
          Text("Team Members", style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
          SizedBox(height: wide ? 16 : 5),
          FutureBuilder(
            future: Future.wait<dynamic>([?membersFuture, ?isAdminFuture]),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text("Error fetching members"));
              }
              if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
                final results = snapshot.data as List<dynamic>;
                final List members = results[0] as List;
                final bool canEditUser = results[1] as bool;

                final Map<String, List> groups = {};
                for (var m in members) {
                  final loc = (m["location"] ?? "Unknown") as String;
                  if (m["username"] == loggedInUsername) {
                    if (members.length - 1 == 0) {
                      return const Center(
                        child: Padding(padding: EdgeInsets.all(16), child: Text("No Members")),
                      );
                    }
                    continue;
                  } else {
                    groups.putIfAbsent(loc, () => []).add(m);
                  }
                }

                final locationTables = groups.entries
                    .map(
                      (entry) => locationTable(context, entry.key, entry.value, canEditUser, scaffoldMessenger, wide),
                    )
                    .toList();

                if (wide) {
                  return Scrollbar(
                    controller: locationScrollController,
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      controller: locationScrollController,
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: locationTables
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
                return Column(children: locationTables);
              }
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator()),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget locationTable(
    BuildContext context,
    String loc,
    List list,
    bool canEditUser,
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
        Text(loc, style: wide ? textTheme.titleMedium : textTheme.titleLarge, textAlign: TextAlign.center),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(children: [cell("Name", headerStyle), cell("Role", headerStyle), cell("Job", headerStyle)]),
        ),
        ...list.map<Widget>((member) {
          final name = member["display_name"] ?? "";
          final role = member["role"] ?? "";
          final job = member["job"] ?? "";

          final row = Row(
            children: [
              cell(name, textTheme.titleSmall),
              cell(role, textTheme.titleSmall),
              cell(job, textTheme.titleSmall),
            ],
          );

          if (!canEditUser) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(children: [const Divider(), row]),
            );
          }

          return Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Tooltip(
              message: "Edit $name",
              child: Material(
                color: Color.fromARGB(50, 0, 255, 145),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  mouseCursor: SystemMouseCursors.click,
                  onTap: () async {
                    final bool? updated = await showEditDialog(context, role, scaffoldMessenger, member);
                    if (updated == true) {
                      setState(() {});
                    }
                  },
                  child: Padding(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14), child: row),
                ),
              ),
            ),
          );
        }),
        SizedBox(height: 16)
      ],
    );
  }
}
