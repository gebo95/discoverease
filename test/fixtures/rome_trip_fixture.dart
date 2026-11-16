import 'package:flutter/material.dart';

import 'package:discoverease/models/trip.dart';
import 'package:discoverease/models/trip_day.dart';
import 'package:discoverease/models/trip_experience.dart';
import 'package:discoverease/models/trip_section.dart';

class RomeTripFixture {
  static Trip day1() {
    return Trip(
      id: 'rome-trip',
      title: 'Rome Vacation',
      destination: 'Rome',
      startDate: DateTime(2027, 5, 18),
      endDate: DateTime(2027, 5, 22),
      days: [
        TripDay(
          title: 'Day 1',
          date: DateTime(2027, 5, 18),
          experiences: [
            TripExperience(
              id: 'coffee',
              listingId: 'coffee',
              section: TripSection.morning,
              time: const TimeOfDay(hour: 9, minute: 0),
              travelMinutes: 5,
            ),
            TripExperience(
              id: 'colosseum',
              listingId: 'colosseum',
              section: TripSection.morning,
              time: const TimeOfDay(hour: 10, minute: 30),
              travelMinutes: 15,
            ),
            TripExperience(
              id: 'lunch',
              listingId: 'lunch',
              section: TripSection.afternoon,
              time: const TimeOfDay(hour: 13, minute: 0),
              travelMinutes: 10,
            ),
            TripExperience(
              id: 'forum',
              listingId: 'roman-forum',
              section: TripSection.afternoon,
              time: const TimeOfDay(hour: 15, minute: 0),
              travelMinutes: 8,
            ),
            TripExperience(
              id: 'dinner',
              listingId: 'dinner',
              section: TripSection.evening,
              time: const TimeOfDay(hour: 19, minute: 30),
              travelMinutes: 12,
            ),
          ],
        ),
      ],
    );
  }
}
