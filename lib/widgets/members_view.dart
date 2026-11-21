import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:lasertracker/core/database.dart';
import 'package:lasertracker/core/layout.dart';
import 'package:lasertracker/models/models.dart';
import 'package:lasertracker/widgets/error_snack.dart';

class MembersView extends StatefulWidget {
  const MembersView({super.key});

  @override
  State<MembersView> createState() => _MembersViewState();
}

class _MembersViewState extends State<MembersView> {
  static const List<String> locations = [
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

  static const List<String> jobs = [
    "Safety Captain",
    "Drive Team - Drive Coach",
    "Drive Team - Driver",
    "Drive Team - Tech Driver",
    "Drive Team - Technician",
    "Drive Team - Human Player",
    "Impact Award Presenter",
    "Student Ambassador",
    "Custom",
  ];

  static const List<String> roles = ["Student", "Mentor", "Lead Coach 1", "Lead Coach 2"];

  User get user => getUser();

  Map<String, List<Member>> get membersByLocation {
    final Map<String, List<Member>> groups = {};
    for (final member in getMembers()) {
      if (member.userName == user.userName) continue;
      groups.putIfAbsent(member.location ?? "Unknown", () => []).add(member);
    }
    return groups;
  }

  final ScrollController locationScrollController = ScrollController();

  final TextEditingController locationController = TextEditingController();
  final TextEditingController jobController = TextEditingController();
  final TextEditingController roleController = TextEditingController();
  final TextEditingController customJobController = TextEditingController();
  final TextEditingController customLocationController = TextEditingController();
  final TextEditingController newPinController = TextEditingController();

  List<DropdownMenuEntry<String>> listToEntries(List<String> list) {
    return list.map((item) => DropdownMenuEntry(value: item, label: item)).toList();
  }

  @override
  void dispose() {
    locationController.dispose();
    jobController.dispose();
    roleController.dispose();
    customJobController.dispose();
    customLocationController.dispose();
    newPinController.dispose();
    locationScrollController.dispose();
    super.dispose();
  }

  Future<bool?> showEditDialog(BuildContext context, ScaffoldMessengerState scaffoldMessenger, Member member) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        final TextEditingController memberRoleController = TextEditingController(text: member.role ?? "");
        bool isAdmin = member.isAdmin ?? false;

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: Text("Edit Member", style: Theme.of(context).textTheme.displaySmall),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownMenu<String>(
                      expandedInsets: EdgeInsets.zero,
                      controller: memberRoleController,
                      label: Text("Role", style: Theme.of(context).textTheme.titleSmall),
                      inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
                      initialSelection: member.role,
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
                      maxLines: 1,
                      decoration: const InputDecoration(labelText: "New Pin (Optional)", border: OutlineInputBorder()),
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                ElevatedButton(
                  onPressed: () async {
                    final navigator = Navigator.of(context);
                    try {
                      if (memberRoleController.text != (member.role ?? "")) {
                        await member.setRole(memberRoleController.text);
                      }
                      if (isAdmin != (member.isAdmin ?? false)) {
                        await member.setAdmin(isAdmin);
                      }
                      if (newPinController.text != "") {
                        await member.changePin(newPinController.text);
                        newPinController.text = "";
                      }
                      scaffoldMessenger.showSnackBar(
                        const SnackBar(
                          content: Text("Member updated successfully!"),
                          behavior: SnackBarBehavior.floating,
                          margin: EdgeInsets.all(16),
                        ),
                      );
                      navigator.pop(true);
                    } catch (e) {
                      ErrorSnack.showErrorSnackBar(scaffoldMessenger, e);
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
    required String customTitle,
    required String customLabel,
    required String customButton,
    required TextEditingController controller,
    required TextEditingController customController,
    required String? current,
    required List<String> options,
    required Future<void> Function(String) onSet,
    required ScaffoldMessengerState scaffoldMessenger,
  }) {
    Future<void> apply(String value) async {
      try {
        await onSet(value);
      } catch (e) {
        controller.text = current ?? "";
        ErrorSnack.showErrorSnackBar(scaffoldMessenger, e);
      }
    }

    return DropdownMenu<String>(
      controller: controller,
      expandedInsets: EdgeInsets.zero,
      label: Text(label),
      inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
      onSelected: (value) {
        if (value == null) return;
        if (value != "Custom") {
          apply(value);
          return;
        }

        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(customTitle, style: Theme.of(context).textTheme.displaySmall),
              content: TextField(
                controller: customController,
                decoration: InputDecoration(labelText: customLabel, border: const OutlineInputBorder()),
              ),
              actions: <Widget>[
                ElevatedButton(
                  onPressed: () {
                    apply(customController.text);
                    controller.text = customController.text;
                    Navigator.pop(context);
                  },
                  child: Text(customButton),
                ),
                ElevatedButton(
                  onPressed: () {
                    controller.text = current ?? "";
                    Navigator.pop(context);
                  },
                  child: const Text('Cancel'),
                ),
              ],
            );
          },
        );
      },
      initialSelection: current,
      dropdownMenuEntries: listToEntries(options),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([Hive.box('members').listenable(), Hive.box('user').listenable()]),
      builder: (context, child) {
        final scaffoldMessenger = ScaffoldMessenger.of(context);
        final wide = isWideScreen(context);
        final user = this.user;

        final statusFields = <Widget>[
          statusDropdown(
            label: "Location",
            customTitle: "Custom Location",
            customLabel: "Location",
            customButton: "Set Location",
            controller: locationController,
            customController: customLocationController,
            current: user.location,
            options: locations,
            onSet: user.setOwnLocation,
            scaffoldMessenger: scaffoldMessenger,
          ),
          statusDropdown(
            label: "Job",
            customTitle: "Custom Job",
            customLabel: "Job Title",
            customButton: "Set Job",
            controller: jobController,
            customController: customJobController,
            current: user.job,
            options: jobs,
            onSet: user.setOwnJob,
            scaffoldMessenger: scaffoldMessenger,
          ),
          DropdownMenu<String>(
            expandedInsets: EdgeInsets.zero,
            controller: roleController,
            enabled: user.isAdmin!,
            label: const Text("Role"),
            inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
            initialSelection: user.role,
            onSelected: (value) async {
              try {
                await user.setOwnRole(value ?? "");
              } catch (e) {
                ErrorSnack.showErrorSnackBar(scaffoldMessenger, e);
              }
            },
            dropdownMenuEntries: listToEntries(roles),
          ),
        ];

        return ListView(
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
            membersSection(context, scaffoldMessenger, wide: wide),
          ],
        );
      },
    );
  }

  Widget membersSection(BuildContext context, ScaffoldMessengerState scaffoldMessenger, {required bool wide}) {
    final groups = membersByLocation;
    if (groups.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text("No Members", style: Theme.of(context).textTheme.bodyLarge),
        ),
      );
    }

    final canEditUser = user.isAdmin ?? false;
    final locationTables = groups.entries
        .map((entry) => locationTable(context, entry.key, entry.value, canEditUser, scaffoldMessenger, wide))
        .toList();

    if (!wide) return Column(children: locationTables);

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

  Widget locationTable(
    BuildContext context,
    String loc,
    List<Member> list,
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
          final name = member.displayName ?? member.userName ?? "";

          final row = Row(
            children: [
              cell(name, textTheme.titleSmall),
              cell(member.role ?? "", textTheme.titleSmall),
              cell(member.job ?? "", textTheme.titleSmall),
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
                color: Theme.of(context).colorScheme.primaryContainer,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  mouseCursor: SystemMouseCursors.click,
                  onTap: () => showEditDialog(context, scaffoldMessenger, member),
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
