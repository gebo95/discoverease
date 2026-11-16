import '../../models/pulse_item.dart';
import '../../models/trip.dart';
import '../../models/trip_day.dart';
import '../../models/trip_experience.dart';
import '../../features/trips/companion/utils/companion_schedule_utils.dart';

/// Builds in-app reminders from dates and times the traveler entered.
/// This does not send operating-system notifications or infer live conditions.
class TripPulseEngine {
  const TripPulseEngine._();

  static const reminderHorizon = Duration(hours: 24);
  static const startReminderLead = Duration(minutes: 15);

  static List<PulseItem> build({
    required Trip trip,
    required DateTime now,
    Map<String, String> listingTitles = const {},
  }) {
    final reminders = <PulseItem>[];

    for (var dayIndex = 0; dayIndex < trip.days.length; dayIndex++) {
      final day = trip.days[dayIndex];
      final date = _dateForDay(trip: trip, day: day, dayIndex: dayIndex);
      if (date == null) continue;

      for (final experience in day.experiences) {
        if (experience.completed || experience.time == null) continue;

        final startsAt = DateTime(
          date.year,
          date.month,
          date.day,
          experience.time!.hour,
          experience.time!.minute,
        );
        final untilStart = startsAt.difference(now);
        if (untilStart.isNegative || untilStart > reminderHorizon) continue;

        final title = listingTitles[experience.listingId] ?? 'Planned experience';
        final reminder = _reminderFor(
          trip: trip,
          day: day,
          dayIndex: dayIndex,
          experience: experience,
          title: title,
          startsAt: startsAt,
          now: now,
        );
        if (reminder != null) reminders.add(reminder);
      }
    }

    reminders.sort((a, b) {
      final byStart = a.scheduledAt!.compareTo(b.scheduledAt!);
      return byStart == 0 ? a.id.compareTo(b.id) : byStart;
    });
    return List.unmodifiable(reminders);
  }

  static PulseItem? _reminderFor({
    required Trip trip,
    required TripDay day,
    required int dayIndex,
    required TripExperience experience,
    required String title,
    required DateTime startsAt,
    required DateTime now,
  }) {
    final options = <_ReminderOption>[];
    final reservation = experience.reservation;

    if (reservation != null) {
      final savedReminderAt = reservation.reminderTime;
      final reminderAt = savedReminderAt != null &&
              savedReminderAt.isBefore(startsAt)
          ? savedReminderAt
          : startsAt.subtract(const Duration(minutes: 60));
      if (!now.isBefore(reminderAt)) {
        options.add(
          _ReminderOption(
            triggerAt: reminderAt,
            type: PulseType.reservation,
            title: 'Reservation coming up',
            message: 'Your reservation for $title is scheduled for '
                '${CompanionScheduleUtils.formatTime(experience.time!)}'
                '${_dateLabel(day.date ?? startsAt, now)}. Keep your confirmation handy.',
          ),
        );
      }
    }

    if (experience.travelMinutes != null) {
      final leaveAt = startsAt.subtract(
        Duration(
          minutes: experience.travelMinutes! + experience.arrivalBufferMinutes,
        ),
      );
      if (!now.isBefore(leaveAt)) {
        options.add(
          _ReminderOption(
            triggerAt: leaveAt,
            type: PulseType.departure,
            title: 'Time to head out',
            message: '$title starts at '
                '${CompanionScheduleUtils.formatTime(experience.time!)}. '
                'Your saved travel estimate is ${experience.travelMinutes} minutes '
                'plus ${experience.arrivalBufferMinutes} minutes to arrive.',
          ),
        );
      }
    }

    final startReminderAt = startsAt.subtract(startReminderLead);
    if (!now.isBefore(startReminderAt)) {
      options.add(
        _ReminderOption(
          triggerAt: startReminderAt,
          type: PulseType.startingSoon,
          title: 'Your plan starts soon',
          message: '$title is scheduled for '
              '${CompanionScheduleUtils.formatTime(experience.time!)}'
              '${_dateLabel(day.date ?? startsAt, now)}.',
        ),
      );
    }

    if (options.isEmpty) return null;
    options.sort((a, b) => b.triggerAt.compareTo(a.triggerAt));
    final selected = options.first;
    final scheduledDate = day.date ?? startsAt;
    final id = '${trip.id}-${experience.id}-${selected.type.name}-'
        '${scheduledDate.year}-${scheduledDate.month}-${scheduledDate.day}';

    return PulseItem(
      id: id,
      listingId: experience.listingId,
      title: selected.title,
      message: selected.message,
      timeLabel: _timeLabel(startsAt: startsAt, now: now),
      type: selected.type,
      scheduledAt: startsAt,
      experienceId: experience.id,
      dayIndex: dayIndex,
      tripDayTitle: day.title,
    );
  }

  static DateTime? _dateForDay({
    required Trip trip,
    required TripDay day,
    required int dayIndex,
  }) {
    if (day.date != null) return day.date;
    if (trip.startDate != null) {
      return trip.startDate!.add(Duration(days: dayIndex));
    }
    return null;
  }

  static String _dateLabel(DateTime date, DateTime now) {
    final targetDay = DateTime(date.year, date.month, date.day);
    final today = DateTime(now.year, now.month, now.day);
    if (targetDay == today) return '';
    if (targetDay == today.add(const Duration(days: 1))) return ' tomorrow';
    return ' on ${date.month}/${date.day}';
  }

  static String _timeLabel({required DateTime startsAt, required DateTime now}) {
    final minutes = startsAt.difference(now).inMinutes;
    if (minutes == 0) return 'Starting now';
    if (minutes < 60) return 'Starts in $minutes min';
    if (startsAt.year == now.year &&
        startsAt.month == now.month &&
        startsAt.day == now.day) {
      final hour = startsAt.hour % 12 == 0 ? 12 : startsAt.hour % 12;
      final minute = startsAt.minute.toString().padLeft(2, '0');
      final period = startsAt.hour < 12 ? 'AM' : 'PM';
      return 'Today at $hour:$minute $period';
    }
    final hour = startsAt.hour % 12 == 0 ? 12 : startsAt.hour % 12;
    final minute = startsAt.minute.toString().padLeft(2, '0');
    final period = startsAt.hour < 12 ? 'AM' : 'PM';
    return '${startsAt.month}/${startsAt.day} at $hour:$minute $period';
  }
}

class _ReminderOption {
  final DateTime triggerAt;
  final PulseType type;
  final String title;
  final String message;

  const _ReminderOption({
    required this.triggerAt,
    required this.type,
    required this.title,
    required this.message,
  });
}
