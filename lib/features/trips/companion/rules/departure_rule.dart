import '../companion_context.dart';
import '../companion_priority.dart';
import '../utils/companion_schedule_utils.dart';
import '../../models/right_now_state.dart';
import 'companion_rule.dart';

class DepartureRule implements CompanionRule {
  const DepartureRule();

  static const int lateWindowMinutes = 30;

  @override
  CompanionPriority get priority => CompanionPriority.urgent;

  @override
  RightNowState? evaluate(CompanionContext context) {
    if (!context.isScheduleToday) return null;

    final candidates = context.day.experiences.where((experience) {
      if (experience.completed ||
          experience.time == null ||
          experience.travelMinutes == null) {
        return false;
      }
      final start = CompanionScheduleUtils.scheduledAt(
        experience,
        context.scheduleDate,
      );
      return !context.now.isAfter(start.add(
        const Duration(minutes: lateWindowMinutes),
      ));
    }).toList()
      ..sort((a, b) => CompanionScheduleUtils.minutes(a.time!).compareTo(
        CompanionScheduleUtils.minutes(b.time!),
      ));

    if (candidates.isEmpty) return null;
    final experience = candidates.first;
    final start = CompanionScheduleUtils.scheduledAt(
      experience,
      context.scheduleDate,
    );
    final leaveAt = CompanionScheduleUtils.departureTime(
      experience: experience,
      date: context.scheduleDate,
    );
    if (context.now.isBefore(leaveAt)) return null;

    final minutesUntilStart = start.difference(context.now).inMinutes;
    final late = minutesUntilStart < 0;
    return RightNowState(
      type: RightNowType.departureSoon,
      eyebrow: 'TRIP COMPANION',
      title: late ? 'Your experience has started' : 'Time to head out',
      message: late
          ? 'It was scheduled for ${CompanionScheduleUtils.formatTime(experience.time!)}. '
                'Travel time was estimated at ${experience.travelMinutes} minutes.'
          : 'It starts in $minutesUntilStart minutes. '
                'Allow about ${experience.travelMinutes} minutes for travel '
                'and ${experience.arrivalBufferMinutes} minutes to arrive.',
      actionLabel: 'View experience',
      action: CompanionAction.openExperience,
      experienceId: experience.id,
    );
  }
}
