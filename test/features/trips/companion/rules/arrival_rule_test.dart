import 'package:flutter_test/flutter_test.dart';

import 'package:discoverease/features/trips/companion/companion_context.dart';
import 'package:discoverease/features/trips/companion/rules/arrival_rule.dart';
import 'package:discoverease/features/trips/models/right_now_state.dart';

import '../../../../builders/day_builder.dart';
import '../../../../builders/experience_builder.dart';
import '../../../../builders/trip_builder.dart';

void main() {
  group('ArrivalRule', () {
    const rule = ArrivalRule();

    test('returns null before the experience starts', () {
      final day = DayBuilder()
          .withExperience(
            ExperienceBuilder().morning().at(10, 0).travelTime(15).build(),
          )
          .build();

      final trip = TripBuilder().withDay(day).build();

      final result = rule.evaluate(
        CompanionContext(
          trip: trip,
          day: day,
          now: DateTime(2026, 7, 27, 9, 45),
        ),
      );

      expect(result, isNull);
    });

    test('returns a start reminder shortly after the scheduled time', () {
      final day = DayBuilder()
          .withExperience(
            ExperienceBuilder().morning().at(10, 0).travelTime(15).build(),
          )
          .build();

      final trip = TripBuilder().withDay(day).build();

      final result = rule.evaluate(
        CompanionContext(
          trip: trip,
          day: day,
          now: DateTime(2026, 7, 27, 10, 2),
        ),
      );

      expect(result, isNotNull);
      expect(result!.type, RightNowType.experienceStarting);
    });

    test('ignores completed experiences', () {
      final day = DayBuilder()
          .withExperience(
            ExperienceBuilder()
                .morning()
                .completed()
                .at(10, 0)
                .travelTime(15)
                .build(),
          )
          .build();

      final trip = TripBuilder().withDay(day).build();

      final result = rule.evaluate(
        CompanionContext(
          trip: trip,
          day: day,
          now: DateTime(2026, 7, 27, 10, 2),
        ),
      );

      expect(result, isNull);
    });
  });
}
