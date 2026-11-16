import '../companion_context.dart';
import '../companion_priority.dart';
import '../utils/companion_schedule_utils.dart';
import '../../models/right_now_state.dart';
import 'companion_rule.dart';

class ReservationRule implements CompanionRule {
  const ReservationRule();

  static const int reminderWindowMinutes = 60;

  @override
  CompanionPriority get priority => CompanionPriority.critical;

  @override
  RightNowState? evaluate(CompanionContext context) {
    if (!context.isScheduleToday) return null;
    final upcoming = context.day.experiences.where((experience) {
      return !experience.completed &&
          experience.time != null &&
          experience.reservation != null;
    }).toList();

    if (upcoming.isEmpty) {
      return null;
    }

    upcoming.sort((a, b) {
      final aTime = CompanionScheduleUtils.toDateTime(a.time!, context.now);

      final bTime = CompanionScheduleUtils.toDateTime(b.time!, context.now);

      return aTime.compareTo(bTime);
    });

    for (final experience in upcoming) {
      final reservation = experience.reservation!;
      final startTime = CompanionScheduleUtils.scheduledAt(
        experience,
        context.scheduleDate,
      );
      final reminder = reservation.reminderTime ??
          CompanionScheduleUtils.scheduledAt(experience, context.scheduleDate)
              .subtract(const Duration(minutes: reminderWindowMinutes));
      final minutesUntilStart = startTime.difference(context.now).inMinutes;

      if (minutesUntilStart < 0 || context.now.isBefore(reminder)) {
        continue;
      }

      final hasTicket =
          reservation.ticketUrl != null &&
          reservation.ticketUrl!.trim().isNotEmpty;

      return RightNowState(
        type: RightNowType.reservationSoon,
        eyebrow: 'RESERVATION',
        title: minutesUntilStart == 0
            ? 'Your reservation starts now'
            : 'Your reservation starts in '
                  '${CompanionScheduleUtils.formatDuration(minutesUntilStart)}',
        message: hasTicket
            ? 'Keep your ticket or confirmation handy. '
                  'The reservation is at '
                  '${CompanionScheduleUtils.formatTime(experience.time!)}.'
            : 'Your reservation is at '
                  '${CompanionScheduleUtils.formatTime(experience.time!)}. '
                  'Keep the confirmation details handy.',
        actionLabel: 'View reservation',
        action: CompanionAction.viewReservation,
        experienceId: experience.id,
        confirmationNumber: reservation.confirmationNumber,
        ticketUrl: reservation.ticketUrl,
      );
    }

    return null;
  }
}
