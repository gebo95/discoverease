import 'package:flutter/material.dart';

import '../companion_context.dart';
import '../companion_priority.dart';
import '../../models/right_now_state.dart';
import '../../../../models/trip_day.dart';
import '../../../../models/trip_experience.dart';

import 'companion_rule.dart';

class FreeTimeRule implements CompanionRule {
  const FreeTimeRule();

  static const int minimumFreeMinutes = 60;

  @override
  CompanionPriority get priority => CompanionPriority.helpful;

  @override
  RightNowState? evaluate(CompanionContext context) {
    if (!context.isScheduleToday) return null;
    final nextExperience = _findNextExperience(
      day: context.day,
      now: context.now,
    );

    if (nextExperience == null || nextExperience.time == null) {
      return null;
    }

    final scheduledTime = DateTime(
      context.scheduleDate.year,
      context.scheduleDate.month,
      context.scheduleDate.day,
      nextExperience.time!.hour,
      nextExperience.time!.minute,
    );

    final hasTravelEstimate = nextExperience.travelMinutes != null;
    final availableUntilDeparture = hasTravelEstimate
        ? scheduledTime
              .subtract(
                Duration(
                  minutes:
                      nextExperience.travelMinutes! +
                      nextExperience.arrivalBufferMinutes,
                ),
              )
              .difference(context.now)
              .inMinutes
        : scheduledTime.difference(context.now).inMinutes;

    if (availableUntilDeparture < minimumFreeMinutes) {
      return null;
    }

    return RightNowState(
      type: RightNowType.freeTime,
      eyebrow: 'Right Now',
      title: 'You have some free time',
      message: hasTravelEstimate
          ? 'You have ${_formatDuration(availableUntilDeparture)} '
                'before you need to leave for your next experience.'
          : 'Your next experience is in '
                '${_formatDuration(availableUntilDeparture)}. '
                'Add a travel estimate to get a leave-time reminder.',
      actionLabel: 'Browse Ideas',
      action: CompanionAction.browseExperiences,
      experienceId: nextExperience.id,
    );
  }

  static TripExperience? _findNextExperience({
    required TripDay day,
    required DateTime now,
  }) {
    final upcomingExperiences = day.experiences.where((experience) {
      if (experience.completed || experience.time == null) {
        return false;
      }

      final scheduledTime = DateTime(
        now.year,
        now.month,
        now.day,
        experience.time!.hour,
        experience.time!.minute,
      );
      return scheduledTime.isAfter(now);
    }).toList();

    if (upcomingExperiences.isEmpty) {
      return null;
    }

    upcomingExperiences.sort((first, second) {
      return _timeToMinutes(
        first.time!,
      ).compareTo(_timeToMinutes(second.time!));
    });

    return upcomingExperiences.first;
  }

  static int _timeToMinutes(TimeOfDay time) {
    return time.hour * 60 + time.minute;
  }

  static String _formatDuration(int totalMinutes) {
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
}
