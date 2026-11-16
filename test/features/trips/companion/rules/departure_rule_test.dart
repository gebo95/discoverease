import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:discoverease/features/trips/companion/rules/departure_rule.dart';
import 'package:discoverease/features/trips/companion/companion_context.dart';
import 'package:discoverease/features/trips/models/right_now_state.dart';

import 'package:discoverease/models/trip.dart';
import 'package:discoverease/models/trip_day.dart';
import 'package:discoverease/models/trip_experience.dart';
import 'package:discoverease/models/trip_section.dart';

void main() {
  group('DepartureRule', () {
    const rule = DepartureRule();

    Trip buildTrip(List<TripExperience> experiences) {
      return Trip(
        id: 'trip-1',
        title: 'Rome',
        destination: 'Rome',
        days: [TripDay(title: 'Day 1', experiences: experiences)],
      );
    }

    test('returns null when there are no experiences', () {
      final trip = buildTrip([]);
      final now = DateTime(2026, 7, 27, 9, 40);

      final result = rule.evaluate(
        CompanionContext(trip: trip, day: trip.days.first, now: now),
      );

      expect(result, isNull);
    });

    test('returns null when travel time is unknown', () {
      final trip = buildTrip([
        TripExperience(
          id: '1',
          listingId: 'coffee',
          section: TripSection.morning,
          time: const TimeOfDay(hour: 10, minute: 0),
        ),
      ]);

      final now = DateTime(2026, 7, 27, 9, 40);
      final result = rule.evaluate(
        CompanionContext(trip: trip, day: trip.days.first, now: now),
      );

      expect(result, isNull);
    });

    test('returns null when it is too early to leave', () {
      final trip = buildTrip([
        TripExperience(
          id: '1',
          listingId: 'coffee',
          section: TripSection.morning,
          time: const TimeOfDay(hour: 10, minute: 0),
          travelMinutes: 10,
        ),
      ]);

      final now = DateTime(2026, 7, 27, 9, 0);

      final result = rule.evaluate(
        CompanionContext(trip: trip, day: trip.days.first, now: now),
      );

      expect(result, isNull);
    });

    test('returns departureSoon when it is time to leave', () {
      final trip = buildTrip([
        TripExperience(
          id: '1',
          listingId: 'coffee',
          section: TripSection.morning,
          time: const TimeOfDay(hour: 10, minute: 0),
          travelMinutes: 10,
        ),
      ]);

      final now = DateTime(2026, 7, 27, 9, 40);

      final result = rule.evaluate(
        CompanionContext(trip: trip, day: trip.days.first, now: now),
      );

      expect(result, isNotNull);
      expect(result!.type, RightNowType.departureSoon);
    });

    test('ignores completed experiences', () {
      final trip = buildTrip([
        TripExperience(
          id: '1',
          listingId: 'coffee',
          section: TripSection.morning,
          completed: true,
          time: const TimeOfDay(hour: 9, minute: 0),
          travelMinutes: 10,
        ),
      ]);

      final now = DateTime(2026, 7, 27, 9, 40);
      final result = rule.evaluate(
        CompanionContext(trip: trip, day: trip.days.first, now: now),
      );

      expect(result, isNull);
    });

    test('returns departureSoon after scheduled time', () {
      final trip = buildTrip([
        TripExperience(
          id: '1',
          listingId: 'coffee',
          section: TripSection.morning,
          time: const TimeOfDay(hour: 10, minute: 0),
          travelMinutes: 10,
        ),
      ]);

      final now = DateTime(2026, 7, 27, 10, 5);
      final result = rule.evaluate(
        CompanionContext(trip: trip, day: trip.days.first, now: now),
      );

      expect(result, isNotNull);
      expect(result!.type, RightNowType.departureSoon);
    });
  });
}
