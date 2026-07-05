import 'package:flutter/material.dart';

import '../../home/pages/home_page.dart';
import '../../saved/pages/saved_page.dart';
import '../../../shared/theme/de_colors.dart';
import '../../explore/pages/explore_page.dart';
import '../../trips/pages/trips_page.dart';

class MainShellPage extends StatefulWidget {
  const MainShellPage({super.key});

  @override
  State<MainShellPage> createState() => _MainShellPageState();
}

class _MainShellPageState extends State<MainShellPage> {
  int _currentIndex = 0;

  final _pages = const [
    HomePage(),
    ExplorePage(),
    SavedPage(),
    TripsPage(),
    SizedBox(child: Center(child: Text("Profile"))),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        backgroundColor: Colors.white,
        indicatorColor: DEColors.primary.withValues(alpha: 0.12),
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: "Home",
          ),
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore_rounded),
            label: "Explore",
          ),
          NavigationDestination(
            icon: Icon(Icons.push_pin_outlined),
            selectedIcon: Icon(Icons.push_pin_rounded),
            label: "Saved",
          ),
          NavigationDestination(
            icon: Icon(Icons.flight_takeoff_outlined),
            selectedIcon: Icon(Icons.flight_takeoff_rounded),
            label: "Trips",
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: "Profile",
          ),
        ],
      ),
    );
  }
}
