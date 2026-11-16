import 'package:flutter/material.dart';

import '../../../models/listing.dart';
import '../../../models/trip.dart';
import '../../../repositories/saved_repository.dart';
import '../../../repositories/trip_repository.dart';
import '../../../shared/components/bottom_sheets/de_on_my_list_actions_sheet.dart';
import '../../../shared/components/bottom_sheets/de_plan_experience_sheet.dart';
import '../../../shared/components/feedback/de_toast.dart';
import '../../listing/pages/listing_detail_page.dart';

class TripDashboardActions {
  const TripDashboardActions._();

  static void openSavedExperience({
    required BuildContext context,
    required Trip trip,
    required Listing listing,
    required SavedRepository savedRepository,
    required TripRepository tripRepository,
    int initialDayIndex = 0,
  }) {
    showDEOnMyListActionsSheet(
      context,
      title: listing.title,
      onViewListing: () {
        viewListing(context: context, listing: listing);
      },
      onPlanExperience: () {
        planExperience(
          context: context,
          trip: trip,
          listing: listing,
          tripRepository: tripRepository,
          initialDayIndex: initialDayIndex,
          successTitle: 'Planned!',
        );
      },
      onRemove: () {
        removeSavedExperience(
          context: context,
          listing: listing,
          savedRepository: savedRepository,
        );
      },
    );
  }

  static void viewListing({
    required BuildContext context,
    required Listing listing,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ListingDetailPage(listing: listing)),
    );
  }

  static void planExperience({
    required BuildContext context,
    required Trip trip,
    required Listing listing,
    required TripRepository tripRepository,
    String successTitle = 'Added',
    int initialDayIndex = 0,
  }) {
    showDEPlanExperienceSheet(
      context,
      experienceTitle: listing.title,
      days: trip.days.map((day) => day.title).toList(),
      initialDayIndex: initialDayIndex,
      onPlan: (
        dayIndex,
        section, {
        time,
        closingTime,
        travelMinutes,
        reservation,
        estimatedCost,
        notes,
      }) {
        tripRepository.planExperience(
          listingId: listing.id,
          dayIndex: dayIndex,
          section: section,
          time: time,
          closingTime: closingTime,
          travelMinutes: travelMinutes,
          reservation: reservation,
          estimatedCost: estimatedCost,
          notes: notes,
        );

        if (!context.mounted) {
          return;
        }

        showDEToast(
          context,
          title: successTitle,
          message: '${listing.title} added to ${trip.days[dayIndex].title}.',
        );
      },
    );
  }

  static void removeSavedExperience({
    required BuildContext context,
    required Listing listing,
    required SavedRepository savedRepository,
  }) {
    savedRepository.remove(listing.id);
    showDEToast(
      context,
      title: 'Removed',
      message: '${listing.title} removed from your list.',
    );
  }

  static void openNextListing({
    required BuildContext context,
    required Listing listing,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ListingDetailPage(listing: listing)),
    );
  }
}
