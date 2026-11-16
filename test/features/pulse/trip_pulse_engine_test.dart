import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:discoverease/features/pulse/trip_pulse_engine.dart';
import 'package:discoverease/models/pulse_item.dart';
import 'package:discoverease/models/trip.dart';
import 'package:discoverease/models/trip_day.dart';
import 'package:discoverease/models/trip_experience.dart';
import 'package:discoverease/models/trip_reservation.dart';
import 'package:discoverease/models/trip_section.dart';

void main() {
  final now = DateTime(2026, 9, 24, 9, 30);

  Trip tripWith(TripExperience experience, {DateTime? startDate}) {
    final date = startDate ?? DateTime(2026, 9, 24);
    return Trip(
      id: 'test-trip',
      title: 'Test trip',
      destination: 'Rome',
      startDate: startDate,
      days: [
        TripDay(
          title: 'Day 1',
          date: date,
          experiences: [experience],
        ),
      ],
    );
  }

  TripExperience experience({
    TimeOfDay time = const TimeOfDay(hour: 10, minute: 0),
    int? travelMinutes,
    int arrivalBufferMinutes = 10,
    TripReservation? reservation,
    bool completed = false,
  }) {
    return TripExperience(
      id: 'experience-1',
      listingId: 'colosseum',
      section: TripSection.morning,
      time: time,
      travelMinutes: travelMinutes,
      arrivalBufferMinutes: arrivalBufferMinutes,
      reservation: reservation,
      completed: completed,
    );
  }

  group('TripPulseEngine', () {
    test('builds a leave reminder from a saved travel estimate', () {
      final reminders = TripPulseEngine.build(
        trip: tripWith(experience(travelMinutes: 20)),
        now: now,
        listingTitles: const {'colosseum': 'Colosseum'},
      );

      expect(reminders, hasLength(1));
      expect(reminders.single.type, PulseType.departure);
      expect(reminders.single.title, 'Time to head out');
      expect(reminders.single.message, contains('Colosseum'));
      expect(reminders.single.dayIndex, 0);
    });

    test('uses the saved reservation reminder time', () {
      final reminders = TripPulseEngine.build(
        trip: tripWith(
          experience(
            reservation: TripReservation(
              type: TripReservationType.tour,
              reminderTime: DateTime(2026, 9, 24, 9, 20),
            ),
          ),
        ),
        now: now,
      );

      expect(reminders, hasLength(1));
      expect(reminders.single.type, PulseType.reservation);
      expect(reminders.single.message, contains('confirmation handy'));
    });

    test('uses the 60 minute reservation default when no time is saved', () {
      final reminders = TripPulseEngine.build(
        trip: tripWith(
          experience(
            reservation: const TripReservation(type: TripReservationType.tour),
          ),
        ),
        now: now,
      );

      expect(reminders.single.type, PulseType.reservation);
    });

    test('reminds about an unticketed scheduled experience 15 minutes before', () {
      final reminders = TripPulseEngine.build(
        trip: tripWith(experience(time: const TimeOfDay(hour: 9, minute: 45))),
        now: now,
      );

      expect(reminders, hasLength(1));
      expect(reminders.single.type, PulseType.startingSoon);
      expect(reminders.single.timeLabel, 'Starts in 15 min');
    });

    test('does not surface reminders outside the 24 hour horizon', () {
      final reminders = TripPulseEngine.build(
        trip: tripWith(
          experience(),
          startDate: DateTime(2026, 9, 26),
        ),
        now: now,
      );

      expect(reminders, isEmpty);
    });

    test('does not remind for completed experiences', () {
      final reminders = TripPulseEngine.build(
        trip: tripWith(experience(travelMinutes: 20, completed: true)),
        now: now,
      );

      expect(reminders, isEmpty);
    });

    test('does not infer a date when an itinerary has no date', () {
      final trip = Trip(
        id: 'undated-trip',
        title: 'Undated trip',
        destination: 'Rome',
        days: [
          TripDay(title: 'Day 1', experiences: [experience(travelMinutes: 20)]),
        ],
      );

      expect(TripPulseEngine.build(trip: trip, now: now), isEmpty);
    });
  });
}
