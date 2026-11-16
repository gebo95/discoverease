import 'package:flutter_test/flutter_test.dart';
import 'package:discoverease/features/trips/companion/companion_context.dart';
import 'package:discoverease/features/trips/companion/rules/reservation_rule.dart';
import 'package:discoverease/features/trips/models/right_now_state.dart';
import '../../../../builders/day_builder.dart';
import '../../../../builders/experience_builder.dart';
import '../../../../builders/trip_builder.dart';

void main() {
  group('ReservationRule', () {
    const rule = ReservationRule();
    final now = DateTime(2026, 7, 27, 9, 0);

    CompanionContext contextFor({
      bool completed = false,
      bool reservation = true,
      DateTime? reminderTime,
      String? ticketUrl,
      String? confirmationNumber,
    }) {
      final builder = ExperienceBuilder().at(10, 0);
      if (completed) builder.completed();
      if (reservation) {
        builder.withReservation(
          reminderTime: reminderTime,
          ticketUrl: ticketUrl,
          confirmationNumber: confirmationNumber,
        );
      }
      final day = DayBuilder().withExperience(builder.build()).build();
      final trip = TripBuilder().withDay(day).build();
      return CompanionContext(trip: trip, day: day, now: now);
    }

    test('returns null when no reservation exists', () {
      expect(rule.evaluate(contextFor(reservation: false)), isNull);
    });

    test('returns null before the default reminder window', () {
      final context = contextFor();
      final result = rule.evaluate(
        CompanionContext(
          trip: context.trip,
          day: context.day,
          now: DateTime(2026, 7, 27, 8, 59),
        ),
      );
      expect(result, isNull);
    });

    test('returns reservation reminder within the default 60 minute window', () {
      final result = rule.evaluate(
        contextFor(ticketUrl: 'https://tickets.example/event', confirmationNumber: 'ABC-123'),
      );
      expect(result?.type, RightNowType.reservationSoon);
      expect(result?.action, CompanionAction.viewReservation);
      expect(result?.ticketUrl, 'https://tickets.example/event');
      expect(result?.confirmationNumber, 'ABC-123');
    });

    test('uses a saved reminder time when present', () {
      final context = contextFor(reminderTime: DateTime(2026, 7, 27, 9, 30));
      expect(rule.evaluate(context), isNull);
      final result = rule.evaluate(
        CompanionContext(
          trip: context.trip,
          day: context.day,
          now: DateTime(2026, 7, 27, 9, 30),
        ),
      );
      expect(result?.type, RightNowType.reservationSoon);
    });

    test('ignores completed experiences', () {
      expect(rule.evaluate(contextFor(completed: true)), isNull);
    });
  });
}
