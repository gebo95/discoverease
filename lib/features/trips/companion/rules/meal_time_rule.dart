import '../companion_context.dart';
import '../companion_priority.dart';
import '../utils/companion_schedule_utils.dart';
import '../../models/right_now_state.dart';
import 'companion_rule.dart';

class MealTimeRule implements CompanionRule {
  const MealTimeRule();

  static const int minimumMealWindowMinutes = 45;

  @override
  CompanionPriority get priority => CompanionPriority.timely;

  @override
  RightNowState? evaluate(CompanionContext context) {
    if (!context.isScheduleToday) return null;
    final meal = _mealFor(context.now);
    if (meal == null) return null;

    final nextExperience = CompanionScheduleUtils.nextExperience(
      day: context.day,
      now: context.now,
    );
    final nextTimedExperience = nextExperience?.time == null
        ? null
        : nextExperience;

    if (nextTimedExperience != null) {
      final timedExperience = nextTimedExperience;
      final latestMealEnd = timedExperience.travelMinutes == null
          ? CompanionScheduleUtils.scheduledAt(
              timedExperience,
              context.scheduleDate,
            )
          : CompanionScheduleUtils.departureTime(
              experience: timedExperience,
              date: context.scheduleDate,
            );
      if (latestMealEnd.difference(context.now).inMinutes <
          minimumMealWindowMinutes) {
        return null;
      }
    }

    return RightNowState(
      type: RightNowType.freeTime,
      eyebrow: 'MEAL BREAK',
      title: 'Time for $meal',
      message: nextTimedExperience == null
          ? 'There are no upcoming timed plans. This is a good time to eat.'
          : nextTimedExperience.travelMinutes == null
          ? 'There is time before your next scheduled start. Travel time is not set for that stop.'
          : 'There is time to eat before you need to leave for your next experience.',
      actionLabel: 'Browse dining',
      action: CompanionAction.browseExperiences,
      browseFilter: '🍽 Hungry',
    );
  }

  String? _mealFor(DateTime now) {
    final minutes = now.hour * 60 + now.minute;
    const lunchStart = 11 * 60 + 30;
    const lunchEnd = 14 * 60;
    const dinnerStart = 17 * 60 + 30;
    const dinnerEnd = 20 * 60 + 30;
    if (minutes >= lunchStart && minutes <= lunchEnd) return 'lunch';
    if (minutes >= dinnerStart && minutes <= dinnerEnd) return 'dinner';
    return null;
  }
}
