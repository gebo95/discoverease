import 'package:flutter/material.dart';

import '../../../models/destination.dart';
import '../../../models/trip.dart';
import '../../../repositories/listing_repository.dart';
import '../../../shared/components/bottom_sheets/de_destination_picker.dart';
import '../../pulse/pages/pulse_page.dart';
import '../../trips/pages/trip_dashboard_page.dart';
import 'de_category_row.dart';
import 'discover_this_week_section.dart';
import 'explore_by_area_section.dart';
import 'home_destination_header.dart';
import 'live_now_section.dart';
import 'your_next_adventure_card.dart';

class HomeContent extends StatelessWidget {
  final Destination destination;
  final Trip trip;
  final int unreadPulseCount;
  final ListingRepository listingRepository;

  const HomeContent({
    super.key,
    required this.destination,
    required this.trip,
    required this.unreadPulseCount,
    required this.listingRepository,
  });

  @override
  Widget build(BuildContext context) {
    final plannedExperienceCount = trip.days.fold<int>(
      0,
      (total, day) => total + day.experiences.length,
    );

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        HomeDestinationHeader(
          flagEmoji: destination.flagEmoji,
          destination: destination.name,
          country: destination.country,
          message: destination.atmosphereMessage,
          unreadPulseCount: unreadPulseCount,
          onDestinationTap: () {
            showDEDestinationPicker(context);
          },
          onPulseTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PulsePage()),
            );
          },
        ),

        const SizedBox(height: 18),

        YourNextAdventureCard(
          title: trip.title,
          destination: trip.destination,
          imageUrl:
              "https://images.unsplash.com/photo-1507525428034-b723cf961d3e",
          daysPlanned: trip.days.length,
          experiencesPlanned: plannedExperienceCount,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => TripDashboardPage(trip: trip)),
            );
          },
        ),

        const SizedBox(height: 40),

        const DiscoverThisWeekSection(),

        const SizedBox(height: 28),

        const LiveNowSection(),

        const SizedBox(height: 40),

        const ExploreByAreaSection(),

        const SizedBox(height: 40),

        ...destination.homeSections.map((section) {
          final listings = listingRepository.getByCategory(
            destination.country,
            section.category,
          );

          if (listings.isEmpty) {
            return const SizedBox.shrink();
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 28),
            child: DECategoryRow(title: section.title, listings: listings),
          );
        }),
      ],
    );
  }
}
