import 'package:flutter/material.dart';

import '../../../shared/components/navigation/de_app_bar.dart';
import '../widgets/home_header.dart';
import '../widgets/live_now_section.dart';
import 'package:provider/provider.dart';

import '../../../repositories/trip_repository.dart';
import '../widgets/your_next_adventure_card.dart';
import '../../trips/pages/trip_dashboard_page.dart';
import '../widgets/discover_this_week_section.dart';
import '../widgets/explore_by_area_section.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final tripRepository = context.watch<TripRepository>();
    final currentTrip = tripRepository.getCurrentTrip();

    final plannedExperienceCount = currentTrip.days.fold<int>(
      0,
      (total, day) => total + day.experiences.length,
    );
    return Scaffold(
      appBar: const DEAppBar(destination: "Bahamas", location: "Nassau"),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          HomeHeader(),

          const SizedBox(height: 18),

          YourNextAdventureCard(
            title: currentTrip.title,
            destination: currentTrip.destination,
            imageUrl:
                "https://images.unsplash.com/photo-1507525428034-b723cf961d3e",
            daysPlanned: currentTrip.days.length,
            experiencesPlanned: plannedExperienceCount,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TripDashboardPage(trip: currentTrip),
                ),
              );
            },
          ),

          SizedBox(height: 40),

          const DiscoverThisWeekSection(),

          SizedBox(height: 28),

          const LiveNowSection(),

          const SizedBox(height: 40),

          const ExploreByAreaSection(),

          const SizedBox(height: 40),

          _SectionTitle(title: "🍽 Top Dining"),

          SizedBox(height: 120),

          _SectionTitle(title: "🚤 Adventures"),

          SizedBox(height: 120),

          _SectionTitle(title: "🏝 Hidden Gems"),

          SizedBox(height: 120),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
    );
  }
}
