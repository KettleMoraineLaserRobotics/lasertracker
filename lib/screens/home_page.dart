import 'package:flutter/material.dart';
import 'package:lasertracker/core/layout.dart';
import 'package:lasertracker/screens/settings_page.dart';
import 'package:lasertracker/widgets/log_view.dart';
import 'package:lasertracker/widgets/members_view.dart';
import 'package:lasertracker/widgets/team_view.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int pageIndex = 0;

  final List<Widget> pages = const [TeamView(), MembersView(), LogView(), SettingsPage()];

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
                leading: Image.asset("../assets/images/tracker_icon.png", width: 64),
                labelType: NavigationRailLabelType.all,
                indicatorColor: const Color.fromARGB(48, 116, 249, 156),
                destinations: const [
                  NavigationRailDestination(
                    icon: Icon(Icons.home),
                    selectedIcon: Icon(Icons.home, color: Color(0xff00ff92)),
                    label: Text('Team'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.radar),
                    selectedIcon: Icon(Icons.radar, color: Color(0xff00ff92)),
                    label: Text('Members'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.access_time),
                    selectedIcon: Icon(Icons.access_time, color: Color(0xff00ff92)),
                    label: Text('Log'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.settings),
                    selectedIcon: Icon(Icons.settings, color: Color(0xff00ff92)),
                    label: Text('Settings'),
                  ),
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
              indicatorColor: const Color.fromARGB(50, 0, 255, 145),
              destinations: const <Widget>[
                NavigationDestination(
                  icon: Icon(Icons.home, color: Color(0xff00ff92)),
                  label: 'Team',
                ),
                NavigationDestination(
                  icon: Icon(Icons.radar, color: Color(0xff00ff92)),
                  label: 'Members',
                ),
                NavigationDestination(
                  icon: Icon(Icons.access_time, color: Color(0xff00ff92)),
                  label: 'Log',
                ),
                NavigationDestination(
                  icon: Icon(Icons.settings, color: Color(0xff00ff92)),
                  label: 'Settings',
                ),
              ],
            ),
    );
  }
}
