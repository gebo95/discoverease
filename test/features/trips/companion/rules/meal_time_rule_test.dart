import 'package:flutter_test/flutter_test.dart';

import 'package:discoverease/features/trips/companion/companion_context.dart';
import 'package:discoverease/features/trips/companion/rules/meal_time_rule.dart';
import 'package:discoverease/features/trips/models/right_now_state.dart';

import '../../../../builders/day_builder.dart';
import '../../../../builders/experience_builder.dart';
import '../../../../builders/trip_builder.dart';

void main() {
  group('MealTimeRule', () {
    const rule = MealTimeRule();

    test('returns null outside meal hours', () {
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

    test('returns null when the next experience is too soon', () {
      final day = DayBuilder()
          .withExperience(ExperienceBuilder().afternoon().at(12, 20).build())
          .build();

      final trip = TripBuilder().withDay(day).build();

      final result = rule.evaluate(
        CompanionContext(
          trip: trip,
          day: day,
          now: DateTime(2026, 7, 27, 12, 0),
        ),
      );

      expect(result, isNull);
    });

    test('returns meal suggestion during lunch with enough free time', () {
      final day = DayBuilder()
          .withExperience(ExperienceBuilder().afternoon().at(14, 0).build())
          .build();

      final trip = TripBuilder().withDay(day).build();

      final result = rule.evaluate(
        CompanionContext(
          trip: trip,
          day: day,
          now: DateTime(2026, 7, 27, 12, 0),
        ),
      );

      expect(result, isNotNull);
      expect(result!.type, RightNowType.freeTime);
      expect(result.title, 'Time for lunch');
    });

    test('returns meal suggestion during dinner with no later experiences', () {
      final day = DayBuilder().build();
      final trip = TripBuilder().withDay(day).build();

      final result = rule.evaluate(
        CompanionContext(
          trip: trip,
          day: day,
          now: DateTime(2026, 7, 27, 18, 30),
        ),
      );

      expect(result, isNotNull);
      expect(result!.type, RightNowType.freeTime);
      expect(result.title, 'Time for dinner');
    });
  });
}
