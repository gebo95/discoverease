import 'package:discoverease/shared/utils/hours_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('clock times read as 12 hour with AM and PM', () {
    expect(formatClock(0), '12:00 AM');
    expect(formatClock(9 * 60), '9:00 AM');
    expect(formatClock(12 * 60), '12:00 PM');
    expect(formatClock(17 * 60 + 5), '5:05 PM');
    expect(formatClock(23 * 60 + 59), '11:59 PM');
  });

  test('days collapse into ranges of three or more', () {
    expect(formatDays({0, 1, 2, 3, 4}), 'Mon–Fri');
    expect(formatDays({5, 6}), 'Sat, Sun');
    expect(formatDays({0, 1}), 'Mon, Tue');
    expect(formatDays({0, 1, 2, 4}), 'Mon–Wed, Fri');
    expect(formatDays({0, 1, 2, 3, 4, 5, 6}), 'Daily');
    expect(formatDays({}), '');
  });

  test('hours join the complete rows and skip the rest', () {
    final text = formatHours([
      const HoursRow(days: {0, 1, 2, 3, 4}, opens: 9 * 60, closes: 17 * 60),
      const HoursRow(days: {5}, opens: 10 * 60, closes: 14 * 60),
      const HoursRow(days: {6}, opens: 10 * 60),
      const HoursRow(days: {}),
    ]);
    expect(text, 'Mon–Fri 9:00 AM – 5:00 PM; Sat 10:00 AM – 2:00 PM');
    expect(formatHours([]), '');
  });

  test('dates read with the weekday', () {
    expect(formatDate(DateTime(2026, 11, 21)), 'Sat, Nov 21, 2026');
  });

  group('schedule', () {
    final friday = DateTime(2026, 11, 27);
    final sunday = DateTime(2026, 11, 29);

    test('one date, with and without a time', () {
      expect(
        formatSchedule(ScheduleChoice(kind: ScheduleKind.date, start: friday)),
        'Fri, Nov 27, 2026',
      );
      expect(
        formatSchedule(ScheduleChoice(kind: ScheduleKind.date, start: friday, time: 20 * 60)),
        'Fri, Nov 27, 2026 · 8:00 PM',
      );
    });

    test('a date range needs both dates in order', () {
      expect(
        formatSchedule(ScheduleChoice(kind: ScheduleKind.range, start: friday, end: sunday)),
        'Fri, Nov 27, 2026 to Sun, Nov 29, 2026',
      );
      expect(formatSchedule(ScheduleChoice(kind: ScheduleKind.range, start: friday)), '');
      expect(
        formatSchedule(ScheduleChoice(kind: ScheduleKind.range, start: sunday, end: friday)),
        '',
      );
    });

    test('a weekly pattern', () {
      expect(
        formatSchedule(const ScheduleChoice(kind: ScheduleKind.weekly, days: {4, 5}, time: 20 * 60)),
        'Every Fri, Sat · 8:00 PM',
      );
      expect(formatSchedule(const ScheduleChoice(kind: ScheduleKind.weekly)), '');
    });

    test('nothing picked gives no text', () {
      expect(formatSchedule(const ScheduleChoice()), '');
    });
  });
}
