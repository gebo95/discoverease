import '../companion_context.dart';
import '../companion_priority.dart';
import '../utils/companion_schedule_utils.dart';
import '../../models/right_now_state.dart';
import 'companion_rule.dart';
import '../../../../models/trip_experience.dart';

class NextExperienceRule implements CompanionRule {
  const NextExperienceRule();

  @override
  CompanionPriority get priority => CompanionPriority.helpful;

  @override
  RightNowState? evaluate(CompanionContext context) {
    if (context.isSchedulePast) return null;
    final experience = CompanionScheduleUtils.nextExperience(
      day: context.day,
      now: context.isScheduleToday ? context.now : context.scheduleDate,
    );
    if (experience == null) return null;

    final time = experience.time;
    final message = time == null
        ? 'This experience is in your plan, but it does not have a start time yet.'
        : _scheduledMessage(context, experience);

    return RightNowState(
      type: RightNowType.nextExperience,
      eyebrow: 'TRIP COMPANION',
      title: 'Your next stop is ready',
      message: message,
      actionLabel: 'View experience',
      action: CompanionAction.openExperience,
      experienceId: experience.id,
    );
  }

  String _scheduledMessage(
    CompanionContext context,
    TripExperience experience,
  ) {
    final time = experience.time!;
    final formatted = CompanionScheduleUtils.formatTime(time);
    if (!context.isScheduleToday) {
      return 'Planned for ${context.scheduleDate.month}/'
          '${context.scheduleDate.day} at $formatted.';
    }
    final minutes = CompanionScheduleUtils.scheduledAt(
      experience,
      context.scheduleDate,
    ).difference(context.now).inMinutes;
    if (minutes <= 0) return 'Scheduled for $formatted.';
    if (minutes < 60) return 'Scheduled for $formatted, in $minutes minutes.';
    final hours = minutes ~/ 60;
    final remainder = minutes % 60;
    return remainder == 0
        ? 'Scheduled for $formatted, in $hours ${hours == 1 ? 'hour' : 'hours'}.'
        : 'Scheduled for $formatted, in $hours ${hours == 1 ? 'hour' : 'hours'} and $remainder minutes.';
  }
}
