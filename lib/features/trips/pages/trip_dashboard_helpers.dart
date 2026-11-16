import 'package:flutter/material.dart';

import '../../../models/listing.dart';
import '../../../models/trip.dart';
import '../../../models/trip_day.dart';
import '../../../models/trip_experience.dart';
import '../../../repositories/listing_repository.dart';
import '../../../repositories/trip_repository.dart';
import '../../../shared/components/trips/de_trip_timeline.dart';

typedef NextTripExperienceResult = ({
  TripExperience experience,
  Listing? listing,
});
typedef EditTripExperience = void Function(TripExperience experience, String title);

class TripDashboardHelpers {
  const TripDashboardHelpers._();

  static NextTripExperienceResult? findNextExperience({
    required Trip trip,
    required ListingRepository listingRepository,
  }) {
    final now = DateTime.now();

    final candidates =
        <
          ({DateTime? scheduledAt, TripExperience experience, Listing? listing})
        >[];

    for (final day in trip.days) {
      for (final experience in day.experiences) {
        if (experience.completed) {
          continue;
        }

        DateTime? scheduledAt;

        if (day.date != null && experience.time != null) {
          scheduledAt = DateTime(
            day.date!.year,
            day.date!.month,
            day.date!.day,
            experience.time!.hour,
            experience.time!.minute,
          );

          if (scheduledAt.isBefore(now)) {
            continue;
          }
        }

        candidates.add((
          scheduledAt: scheduledAt,
          experience: experience,
          listing: listingRepository.getById(experience.listingId),
        ));
      }
    }

    if (candidates.isEmpty) {
      return null;
    }

    candidates.sort((a, b) {
      if (a.scheduledAt == null && b.scheduledAt == null) {
        return 0;
      }

      if (a.scheduledAt == null) {
        return 1;
      }

      if (b.scheduledAt == null) {
        return -1;
      }

      return a.scheduledAt!.compareTo(b.scheduledAt!);
    });

    final result = candidates.first;

    return (experience: result.experience, listing: result.listing);
  }

  static String? formatNextUpTime({
    required BuildContext context,
    required Trip trip,
    required TripExperience? experience,
  }) {
    if (experience == null) {
      return null;
    }

    TripDay? matchingDay;

    for (final day in trip.days) {
      if (day.experiences.contains(experience)) {
        matchingDay = day;
        break;
      }
    }

    final formattedTime = experience.time?.format(context);

    if (matchingDay == null) {
      return formattedTime;
    }

    if (matchingDay.date == null) {
      if (formattedTime == null) {
        return matchingDay.title;
      }

      return '${matchingDay.title} • $formattedTime';
    }

    final now = DateTime.now();
    final date = matchingDay.date!;

    final today = DateTime(now.year, now.month, now.day);
    final scheduledDay = DateTime(date.year, date.month, date.day);
    final difference = scheduledDay.difference(today).inDays;

    final dayLabel = switch (difference) {
      0 => 'Today',
      1 => 'Tomorrow',
      _ => matchingDay.title,
    };

    if (formattedTime == null) {
      return dayLabel;
    }

    return '$dayLabel • $formattedTime';
  }

  static List<DETimelineItem> buildTimelineItems({
    required BuildContext context,
    required TripDay selectedDay,
    required ListingRepository listingRepository,
    required TripRepository tripRepository,
    EditTripExperience? onEditExperience,
  }) {
    return selectedDay.experiences.map((tripExperience) {
      final listing = listingRepository.getById(tripExperience.listingId);
      final editExperience = onEditExperience;

      return DETimelineItem(
        title: listing?.title ?? 'Unknown Experience',
        time: tripExperience.time,
        note: tripExperience.notes,
        estimatedCost: tripExperience.estimatedCost,
        completed: tripExperience.completed,
        section: tripExperience.section,
        onCompletedChanged: (completed) {
          tripRepository.setExperienceCompleted(
            experienceId: tripExperience.id,
            completed: completed,
          );
        },
        onEdit: editExperience == null
            ? null
            : () => editExperience(tripExperience, listing?.title ?? 'Experience'),
        onRemove: () {
          showDialog<bool>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: const Text('Remove this experience?'),
              content: Text('Remove ${listing?.title ?? 'this experience'} from your trip?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Keep it'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: const Text('Remove'),
                ),
              ],
            ),
          ).then((confirmed) {
            if (confirmed == true) {
              tripRepository.removeExperience(tripExperience.id);
            }
          });
        },
      );
    }).toList();
  }

  static int completedExperienceCount(TripDay day) {
    return day.experiences.where((experience) => experience.completed).length;
  }
}
