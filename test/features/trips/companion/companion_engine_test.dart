import 'package:flutter_test/flutter_test.dart';
import 'package:discoverease/features/trips/companion/companion_context.dart';
import 'package:discoverease/features/trips/companion/companion_engine.dart';
import 'package:discoverease/features/trips/companion/companion_priority.dart';
import 'package:discoverease/features/trips/companion/rules/companion_rule.dart';
import 'package:discoverease/features/trips/models/right_now_state.dart';
import 'package:discoverease/models/trip_reservation.dart';
import '../../../builders/day_builder.dart';
import '../../../builders/experience_builder.dart';
import '../../../builders/trip_builder.dart';

void main() {
  group('CompanionEngine', () {
    test('prioritizes a reservation reminder over other suggestions', () {
      final day = DayBuilder()
          .withExperience(
            ExperienceBuilder()
                .at(10, 0)
                .travelTime(10)
                .withReservation(
                  type: TripReservationType.restaurant,
                  confirmationNumber: 'R-123',
                )
                .build(),
          )
          .build();
      final trip = TripBuilder().withDay(day).build();

      final result = CompanionEngine.build(
        trip: trip,
        day: day,
        now: DateTime(2026, 7, 27, 9, 10),
      );

      expect(result.type, RightNowType.reservationSoon);
    });

    test('returns a browse action for an empty day', () {
      final day = DayBuilder().build();
      final trip = TripBuilder().withDay(day).build();

      final result = CompanionEngine.build(
        trip: trip,
        day: day,
        now: DateTime(2026, 7, 27, 9),
      );

      expect(result.type, RightNowType.nothingPlanned);
      expect(result.action, CompanionAction.browseExperiences);
    });

    test('can compose an extra rule without changing built-in rule order', () {
      final day = DayBuilder().build();
      final trip = TripBuilder().withDay(day).build();
      final result = CompanionEngine.build(
        trip: trip,
        day: day,
        now: DateTime(2026, 7, 27, 9),
        additionalRules: const [_TestRule()],
      );
      expect(result.title, 'External data available');
    });

    test('does not describe a future itinerary day as happening now', () {
      final day = DayBuilder()
          .date(DateTime(2026, 8, 2))
          .withExperience(ExperienceBuilder().at(9, 0).build())
          .build();
      final trip = TripBuilder().withDay(day).build();
      final result = CompanionEngine.build(
        trip: trip,
        day: day,
        now: DateTime(2026, 7, 27, 9),
      );
      expect(result.type, RightNowType.nextExperience);
      expect(result.message, contains('8/2 at 9:00 AM'));
    });

    test('does not describe a past itinerary as the next experience', () {
      final day = DayBuilder()
          .date(DateTime(2026, 7, 26))
          .withExperience(ExperienceBuilder().at(9, 0).build())
          .build();
      final trip = TripBuilder().withDay(day).build();
      final result = CompanionEngine.build(
        trip: trip,
        day: day,
        now: DateTime(2026, 7, 27, 9),
      );
      expect(result.title, 'This day has passed');
      expect(result.action, isNull);
    });
  });
}

class _TestRule implements CompanionRule {
  const _TestRule();

  @override
  CompanionPriority get priority => CompanionPriority.discovery;

  @override
  RightNowState? evaluate(CompanionContext context) => const RightNowState(
    type: RightNowType.nearbyEvent,
    eyebrow: 'TEST',
    title: 'External data available',
    message: 'This is supplied by a composed rule.',
  );
}
