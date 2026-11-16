import 'package:flutter/material.dart';

import '../../../repositories/listing_repository.dart';
import '../../../repositories/saved_repository.dart';
import '../../../repositories/trip_repository.dart';

import '../../../shared/components/trips/de_saved_for_later_section.dart';

import '../companion/companion_engine.dart';

import 'trip_dashboard_actions.dart';
import 'trip_dashboard_helpers.dart';
import 'trip_dashboard_state.dart';
import 'trip_saved_filter.dart';

class TripDashboardFactory {
  const TripDashboardFactory._();

  static TripDashboardState build({
    required BuildContext context,
    required int selectedDayIndex,
    required ListingRepository listingRepository,
    required SavedRepository savedRepository,
    required TripRepository tripRepository,
    EditTripExperience? onEditExperience,
  }) {
    final trip = tripRepository.getCurrentTrip();

    if (trip.days.isEmpty) {
      throw StateError('Cannot build dashboard state with no trip days.');
    }

    final safeSelectedDayIndex = selectedDayIndex.clamp(
      0,
      trip.days.length - 1,
    );

    final selectedDay = trip.days[safeSelectedDayIndex];

    // Resolve by stable catalog destination ID when trip and save display
    // names differ, such as Nassau and Bahamas.
    final tripSavedExperiences = TripSavedFilter.forTrip(
      trip: trip,
      saved: savedRepository.getAllSaved(),
      listings: listingRepository,
      isPlanned: tripRepository.isListingPlanned,
      includePlanned: true,
    );
    final savedExperiences = tripSavedExperiences
        .where((saved) => !tripRepository.isListingPlanned(saved.listingId))
        .toList(growable: false);

    final completedExperiences = TripDashboardHelpers.completedExperienceCount(
      selectedDay,
    );

    final rightNow = CompanionEngine.build(
      trip: trip,
      day: selectedDay,
      now: DateTime.now(),
    );

    final timelineItems = TripDashboardHelpers.buildTimelineItems(
      context: context,
      selectedDay: selectedDay,
      listingRepository: listingRepository,
      tripRepository: tripRepository,
      onEditExperience: onEditExperience,
    );

    final savedItems = savedExperiences
        .map((saved) {
          final listing = listingRepository.getById(saved.listingId);

          if (listing == null) {
            return null;
          }

          return DESavedForLaterItem(
            title: listing.title,
            imageUrl: listing.imageUrl,
            onTap: () {
              TripDashboardActions.openSavedExperience(
                context: context,
                trip: trip,
                listing: listing,
                savedRepository: savedRepository,
                tripRepository: tripRepository,
                initialDayIndex: safeSelectedDayIndex,
              );
            },
            onAddToDay: () {
              TripDashboardActions.planExperience(
                context: context,
                trip: trip,
                listing: listing,
                tripRepository: tripRepository,
                initialDayIndex: safeSelectedDayIndex,
              );
            },
          );
        })
        .whereType<DESavedForLaterItem>()
        .toList();

    return TripDashboardState(
      trip: trip,
      selectedDay: selectedDay,
      selectedDayIndex: safeSelectedDayIndex,
      savedCount: tripSavedExperiences.length,
      completedExperiences: completedExperiences,
      rightNow: rightNow,
      timelineItems: timelineItems,
      savedItems: savedItems,
    );
  }
}
