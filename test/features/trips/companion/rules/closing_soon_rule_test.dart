import 'package:flutter_test/flutter_test.dart';
import 'package:discoverease/features/trips/companion/companion_context.dart';
import 'package:discoverease/features/trips/companion/rules/closing_soon_rule.dart';
import 'package:discoverease/features/trips/models/right_now_state.dart';
import '../../../../builders/day_builder.dart';
import '../../../../builders/experience_builder.dart';
import '../../../../builders/trip_builder.dart';

void main() {
  group('ClosingSoonRule', () {
    const rule = ClosingSoonRule();
    final now = DateTime(2026, 7, 27, 17, 30);

    CompanionContext contextFor({
      int? closeHour,
      int closeMinute = 0,
      bool completed = false,
    }) {
      final builder = ExperienceBuilder();
      if (closeHour != null) builder.closesAt(closeHour, closeMinute);
      if (completed) builder.completed();
      final day = DayBuilder().withExperience(builder.build()).build();
      final trip = TripBuilder().withDay(day).build();
      return CompanionContext(trip: trip, day: day, now: now);
    }

    test('returns null when no closing time exists', () {
      expect(rule.evaluate(contextFor()), isNull);
    });

    test('returns null when there is plenty of time remaining', () {
      expect(rule.evaluate(contextFor(closeHour: 20)), isNull);
    });

    test('returns a closing warning when the saved time is within an hour', () {
      final result = rule.evaluate(
        contextFor(closeHour: 18, closeMinute: 0),
      );
      expect(result?.type, RightNowType.closingSoon);
      expect(result?.action, CompanionAction.openExperience);
      expect(result?.title, 'Closes in 30 minutes');
    });

    test('ignores completed experiences', () {
      expect(
        rule.evaluate(contextFor(closeHour: 18, completed: true)),
        isNull,
      );
    });
  });
}
