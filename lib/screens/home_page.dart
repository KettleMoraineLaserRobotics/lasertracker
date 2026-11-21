import 'package:flutter/material.dart';
import 'package:lasertracker/core/layout.dart';
import 'package:lasertracker/widgets/batteries_view.dart';
import 'package:lasertracker/widgets/log_view.dart';
import 'package:lasertracker/widgets/members_view.dart';
import 'package:lasertracker/widgets/settings_view.dart';
import 'package:lasertracker/widgets/team_view.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int pageIndex = 0;

  final List<Widget> pages = const [TeamView(), MembersView(), BatteriesView(), LogView(), SettingsView()];

  @override
  Widget build(BuildContext context) {
    final wide = isWideScreen(context);
    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            if (wide)
              NavigationRail(
                selectedIndex: pageIndex,
                onDestinationSelected: (int index) {
                  setState(() {
                    pageIndex = index;
                  });
                },
                leading: Image.asset(
                  "assets/images/tracker_icon.png",
                  width: 64,
                  color: Theme.of(context).colorScheme.primary,
                  colorBlendMode: BlendMode.srcIn,
                ),
                destinations: const [
                  NavigationRailDestination(icon: Icon(Icons.home), label: Text('Team')),
                  NavigationRailDestination(icon: Icon(Icons.radar), label: Text('Members')),
                  NavigationRailDestination(icon: Icon(Icons.battery_0_bar), label: Text('Batteries')),
                  NavigationRailDestination(icon: Icon(Icons.access_time), label: Text('Log')),
                  NavigationRailDestination(icon: Icon(Icons.settings), label: Text('Settings')),
                ],
              ),
            Expanded(key: const ValueKey("page"), child: pages[pageIndex]),
          ],
        ),
      ),
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              selectedIndex: pageIndex,
              onDestinationSelected: (int index) {
                setState(() {
                  pageIndex = index;
                });
              },
              destinations: const <Widget>[
                NavigationDestination(icon: Icon(Icons.home), label: 'Team'),
                NavigationDestination(icon: Icon(Icons.radar), label: 'Members'),
                NavigationDestination(icon: Icon(Icons.battery_0_bar), label: 'Batteries'),
                NavigationDestination(icon: Icon(Icons.access_time), label: 'Log'),
                NavigationDestination(icon: Icon(Icons.settings), label: 'Settings'),
              ],
            ),
    );
  }
}
