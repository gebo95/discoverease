import '../../../models/trip.dart';
import '../../../models/trip_day.dart';
import '../../../shared/components/trips/de_saved_for_later_section.dart';
import '../../../shared/components/trips/de_trip_timeline.dart';
import '../models/right_now_state.dart';

class TripDashboardState {
  final Trip trip;
  final TripDay selectedDay;
  final int selectedDayIndex;

  final int savedCount;
  final int completedExperiences;

  final RightNowState rightNow;

  final List<DETimelineItem> timelineItems;
  final List<DESavedForLaterItem> savedItems;

  const TripDashboardState({
    required this.trip,
    required this.selectedDay,
    required this.selectedDayIndex,
    required this.savedCount,
    required this.completedExperiences,
    required this.rightNow,
    required this.timelineItems,
    required this.savedItems,
  });
}
