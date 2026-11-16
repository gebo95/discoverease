import '../companion_context.dart';
import '../companion_priority.dart';
import '../utils/companion_schedule_utils.dart';
import '../../models/right_now_state.dart';
import 'companion_rule.dart';

/// Warns from a closing time explicitly saved on a planned experience.
/// This rule does not fetch venue hours or verify that the traveler is there.
class ClosingSoonRule implements CompanionRule {
  const ClosingSoonRule();

  static const int warningWindowMinutes = 60;

  @override
  CompanionPriority get priority => CompanionPriority.timely;

  @override
  RightNowState? evaluate(CompanionContext context) {
    if (!context.isScheduleToday) return null;

    final candidates = context.day.experiences.where((experience) {
      return !experience.completed && experience.closingTime != null;
    }).toList()
      ..sort((a, b) => CompanionScheduleUtils.minutes(
        a.closingTime!,
      ).compareTo(CompanionScheduleUtils.minutes(b.closingTime!)));

    for (final experience in candidates) {
      final closingAt = CompanionScheduleUtils.toDateTime(
        experience.closingTime!,
        context.scheduleDate,
      );
      final minutesUntilClose = closingAt.difference(context.now).inMinutes;
      if (minutesUntilClose < 0 || minutesUntilClose > warningWindowMinutes) {
        continue;
      }

      return RightNowState(
        type: RightNowType.closingSoon,
        eyebrow: 'TRIP COMPANION',
        title: minutesUntilClose == 0
            ? 'Closing time is now'
            : 'Closes in $minutesUntilClose minutes',
        message: 'The closing time saved for this planned stop is '
            '${CompanionScheduleUtils.formatTime(experience.closingTime!)}. '
            'Check the venue for current hours.',
        actionLabel: 'View experience',
        action: CompanionAction.openExperience,
        experienceId: experience.id,
      );
    }

    return null;
  }
}
