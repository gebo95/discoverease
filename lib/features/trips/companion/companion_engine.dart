import '../../../models/trip.dart';
import '../../../models/trip_day.dart';
import '../models/right_now_state.dart';
import 'companion_context.dart';
import 'rules/arrival_rule.dart';
import 'rules/companion_rule.dart';
import 'rules/closing_soon_rule.dart';
import 'rules/departure_rule.dart';
import 'rules/free_time_rule.dart';
import 'rules/meal_time_rule.dart';
import 'rules/next_experience_rule.dart';
import 'rules/reservation_rule.dart';

class CompanionEngine {
  const CompanionEngine._();

  static final List<CompanionRule> _rules = [
    const ReservationRule(),
    const DepartureRule(),
    const ClosingSoonRule(),
    const ArrivalRule(),
    const MealTimeRule(),
    const FreeTimeRule(),
    const NextExperienceRule(),
  ];

  static RightNowState build({
    required Trip trip,
    required TripDay day,
    required DateTime now,
    List<CompanionRule> additionalRules = const [],
  }) {
    final context = CompanionContext(trip: trip, day: day, now: now);
    final rules = [..._rules, ...additionalRules].indexed.toList()
      ..sort((a, b) {
        final byPriority = a.$2.priority.index.compareTo(b.$2.priority.index);
        return byPriority == 0 ? a.$1.compareTo(b.$1) : byPriority;
      });

    for (final entry in rules) {
      final result = entry.$2.evaluate(context);
      if (result != null) return result;
    }

    final hasAnyPlannedExperience = day.experiences.any(
      (experience) => !experience.completed,
    );
    if (context.isSchedulePast) {
      return const RightNowState(
        type: RightNowType.nothingPlanned,
        eyebrow: 'TRIP COMPANION',
        title: 'This day has passed',
        message: 'Your itinerary is still here if you want to review it.',
      );
    }
    return RightNowState(
      type: hasAnyPlannedExperience
          ? RightNowType.freeTime
          : RightNowType.nothingPlanned,
      eyebrow: 'TRIP COMPANION',
      title: hasAnyPlannedExperience ? 'Your day is open' : 'Nothing planned yet',
      message: hasAnyPlannedExperience
          ? 'No upcoming timed plans for this day. Take it easy or explore the destination.'
          : 'Add an experience to your itinerary, or leave the day open.',
      actionLabel: 'Browse experiences',
      action: CompanionAction.browseExperiences,
    );
  }
}
