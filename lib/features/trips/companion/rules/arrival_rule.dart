import '../companion_context.dart';
import '../companion_priority.dart';
import '../utils/companion_schedule_utils.dart';
import '../../models/right_now_state.dart';
import 'companion_rule.dart';

/// Surfaces a schedule-based start reminder. Arrival detection itself needs
/// device location and is intentionally not inferred from the clock.
class ArrivalRule implements CompanionRule {
  const ArrivalRule();

  static const int startReminderMinutes = 15;

  @override
  CompanionPriority get priority => CompanionPriority.timely;

  @override
  RightNowState? evaluate(CompanionContext context) {
    if (!context.isScheduleToday) return null;

    final candidates = context.day.experiences.where((experience) {
      if (experience.completed || experience.time == null) {
        return false;
      }
      final start = CompanionScheduleUtils.scheduledAt(
        experience,
        context.scheduleDate,
      );
      final minutesFromStart = context.now.difference(start).inMinutes;
      return minutesFromStart >= 0 &&
          minutesFromStart <= startReminderMinutes;
    }).toList()
      ..sort((a, b) => CompanionScheduleUtils.minutes(a.time!).compareTo(
        CompanionScheduleUtils.minutes(b.time!),
      ));

    if (candidates.isEmpty) return null;
    final experience = candidates.first;
    return RightNowState(
      type: RightNowType.experienceStarting,
      eyebrow: 'TRIP COMPANION',
      title: 'Your experience is starting',
      message: 'It was scheduled for '
          '${CompanionScheduleUtils.formatTime(experience.time!)}. '
          'Check your plan for the details.',
      actionLabel: 'View experience',
      action: CompanionAction.openExperience,
      experienceId: experience.id,
    );
  }
}
