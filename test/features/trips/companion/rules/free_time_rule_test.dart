import 'package:flutter_test/flutter_test.dart';

import 'package:discoverease/features/trips/companion/companion_context.dart';
import 'package:discoverease/features/trips/companion/rules/free_time_rule.dart';
import 'package:discoverease/features/trips/models/right_now_state.dart';

import '../../../../builders/experience_builder.dart';
import '../../../../builders/day_builder.dart';
import '../../../../builders/trip_builder.dart';

void main() {
  group('FreeTimeRule', () {
    const rule = FreeTimeRule();

    test('returns null when there are no upcoming experiences', () {
      final day = DayBuilder().build();
      final trip = TripBuilder().withDay(day).build();

      final result = rule.evaluate(
        CompanionContext(
          trip: trip,
          day: day,
          now: DateTime(2026, 7, 27, 9, 0),
        ),
      );

      expect(result, isNull);
    });

    test('returns freeTime when there is more than one hour available', () {
      final trip = TripBuilder()
          .withDay(
            DayBuilder()
                .withExperience(
                  ExperienceBuilder()
                      .morning()
                      .at(12, 0)
                      .travelTime(15)
                      .build(),
                )
                .build(),
          )
          .build();

      final result = rule.evaluate(
        CompanionContext(
          trip: trip,
          day: trip.days.first,
          now: DateTime(2026, 7, 27, 9, 30),
        ),
      );

      expect(result, isNotNull);
      expect(result!.type, RightNowType.freeTime);
    });

    test('returns null when departure time is approaching', () {
      final trip = TripBuilder()
          .withDay(
            DayBuilder()
                .withExperience(
                  ExperienceBuilder()
                      .morning()
                      .at(10, 0)
                      .travelTime(15)
                      .build(),
                )
                .build(),
          )
          .build();

      final result = rule.evaluate(
        CompanionContext(
          trip: trip,
          day: trip.days.first,
          now: DateTime(2026, 7, 27, 9, 50),
        ),
      );

      expect(result, isNull);
    });
  });
}
