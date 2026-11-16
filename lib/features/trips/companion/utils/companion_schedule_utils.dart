import 'package:flutter/material.dart';

import '../../../../models/trip_day.dart';
import '../../../../models/trip_experience.dart';

class CompanionScheduleUtils {
  const CompanionScheduleUtils._();

  static TripExperience? nextExperience({
    required TripDay day,
    required DateTime now,
  }) {
    final upcoming = day.experiences.where((experience) {
      if (experience.completed) return false;
      if (experience.time == null) return true;
      return toDateTime(experience.time!, now).isAfter(now);
    }).toList();

    if (upcoming.isEmpty) {
      return null;
    }

    upcoming.sort((a, b) {
      if (a.time == null && b.time == null) return 0;
      if (a.time == null) return 1;
      if (b.time == null) return -1;
      return minutes(a.time!).compareTo(minutes(b.time!));
    });

    return upcoming.first;
  }

  static DateTime toDateTime(TimeOfDay time, DateTime date) {
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  static DateTime scheduledAt(TripExperience experience, DateTime date) =>
      toDateTime(experience.time!, date);

  static int minutes(TimeOfDay time) {
    return time.hour * 60 + time.minute;
  }

  static DateTime departureTime({
    required TripExperience experience,
    required DateTime date,
  }) {
    return toDateTime(experience.time!, date).subtract(
      Duration(
        minutes:
            (experience.travelMinutes ?? 0) + experience.arrivalBufferMinutes,
      ),
    );
  }

  static String formatDuration(int totalMinutes) {
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;

    if (hours == 0) {
      return '$minutes minutes';
    }

    if (minutes == 0) {
      return '$hours ${hours == 1 ? 'hour' : 'hours'}';
    }

    return '$hours ${hours == 1 ? 'hour' : 'hours'} '
        'and $minutes minutes';
  }

  static String formatTime(TimeOfDay time) {
    final period = time.hour >= 12 ? 'PM' : 'AM';
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');

    return '$hour:$minute $period';
  }
}
