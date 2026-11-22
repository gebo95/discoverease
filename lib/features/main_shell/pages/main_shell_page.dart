import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../main_shell_controller.dart';
import '../../home/pages/home_page.dart';
import '../../saved/pages/saved_page.dart';
import '../../../shared/theme/de_colors.dart';
import '../../explore/pages/explore_page.dart';
import '../../trips/pages/trips_page.dart';
import '../../profile/pages/profile_page.dart';

class MainShellPage extends StatefulWidget {
  const MainShellPage({super.key});

  @override
  State<MainShellPage> createState() => _MainShellPageState();
}

class _MainShellPageState extends State<MainShellPage> {
  int _currentIndex = 0;
  final _controller = MainShellController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onExploreRequested);
  }

  @override
  void dispose() {
    _controller.removeListener(_onExploreRequested);
    _controller.dispose();
    super.dispose();
  }

  void _onExploreRequested() => setState(() => _currentIndex = 1);

  Widget get _page {
    switch (_currentIndex) {
      case 0:
        return const HomePage();
      case 1:
        return ExplorePage(
          key: ValueKey('explore-${_controller.requestId}'),
          initialCategory: _controller.category,
          initialAreaId: _controller.areaId,
          initialFilter: _controller.filter,
        );
      case 2:
        return const SavedPage();
      case 3:
        return const TripsPage();
      default:
        return const ProfilePage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<MainShellController>.value(
      value: _controller,
      child: _scaffold(),
    );
  }

  Widget _scaffold() {
    return Scaffold(
      body: _page,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        backgroundColor: Colors.white,
        indicatorColor: DEColors.primary.withValues(alpha: 0.12),
        onDestinationSelected: (index) {
          // Opening Explore from the bar starts from a clean slate.
          if (index == 1) _controller.clear();
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
