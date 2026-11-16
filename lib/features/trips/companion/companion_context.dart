import '../../../models/trip.dart';
import '../../../models/trip_day.dart';

class CompanionContext {
  final Trip trip;
  final TripDay day;
  final DateTime now;

  const CompanionContext({
    required this.trip,
    required this.day,
    required this.now,
  });

  DateTime get scheduleDate {
    final date = day.date ?? now;
    return DateTime(date.year, date.month, date.day);
  }

  bool get isScheduleToday {
    final today = DateTime(now.year, now.month, now.day);
    return scheduleDate == today;
  }

  bool get isSchedulePast => scheduleDate.isBefore(
    DateTime(now.year, now.month, now.day),
  );

  DateTime atScheduledTime(int hour, int minute) => DateTime(
    scheduleDate.year,
    scheduleDate.month,
    scheduleDate.day,
    hour,
    minute,
  );
}
