import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:discoverease/models/trip_schedule_validation.dart';
import 'package:discoverease/models/trip_section.dart';

void main() {
  group('TripScheduleValidation', () {
    test('does not warn when time matches the chosen part of day', () {
      expect(
        TripScheduleValidation.warningFor(
          TripSection.morning,
          const TimeOfDay(hour: 9, minute: 0),
        ),
        isNull,
      );
      expect(
        TripScheduleValidation.warningFor(
          TripSection.evening,
          const TimeOfDay(hour: 20, minute: 0),
        ),
        isNull,
      );
    });

    test('returns a helpful warning when time conflicts with selected section', () {
      expect(
        TripScheduleValidation.warningFor(
          TripSection.morning,
          const TimeOfDay(hour: 21, minute: 0),
        ),
        contains('may not fit the morning'),
      );
    });

    test('does not warn until both a section and a time are selected', () {
      expect(TripScheduleValidation.warningFor(null, const TimeOfDay(hour: 21, minute: 0)), isNull);
      expect(TripScheduleValidation.warningFor(TripSection.evening, null), isNull);
    });
  });
}
