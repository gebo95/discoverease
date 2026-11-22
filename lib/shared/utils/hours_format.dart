/// Turns picker choices into the plain text travelers read as "Hours" and
/// "When it happens". Kept free of Flutter so it can be unit tested.
library;

const List<String> dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

const List<String> _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// 0 to 1439 minutes after midnight, as "9:00 AM".
String formatClock(int minutesOfDay) {
  final hour24 = (minutesOfDay ~/ 60) % 24;
  final minute = minutesOfDay % 60;
  final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
  return '$hour12:${minute.toString().padLeft(2, '0')} ${hour24 < 12 ? 'AM' : 'PM'}';
}

/// Day numbers 0 (Monday) to 6 (Sunday), for example "Mon–Fri", "Sat, Sun"
/// or "Daily".
String formatDays(Iterable<int> days) {
  final sorted = days.where((d) => d >= 0 && d < 7).toSet().toList()..sort();
  if (sorted.isEmpty) return '';
  if (sorted.length == 7) return 'Daily';
  final parts = <String>[];
  var start = 0;
  while (start < sorted.length) {
    var end = start;
    while (end + 1 < sorted.length && sorted[end + 1] == sorted[end] + 1) {
      end++;
    }
    final length = end - start + 1;
    if (length >= 3) {
      parts.add('${dayNames[sorted[start]]}–${dayNames[sorted[end]]}');
    } else {
      for (var i = start; i <= end; i++) {
        parts.add(dayNames[sorted[i]]);
      }
    }
    start = end + 1;
  }
  return parts.join(', ');
}

class HoursRow {
  const HoursRow({required this.days, this.opens, this.closes});
  final Set<int> days;
  final int? opens;
  final int? closes;

  bool get isComplete => days.isNotEmpty && opens != null && closes != null;
}

/// One line per complete row, joined with "; ". Incomplete rows are skipped.
String formatHours(List<HoursRow> rows) => rows
    .where((row) => row.isComplete)
    .map((row) =>
        '${formatDays(row.days)} ${formatClock(row.opens!)} – ${formatClock(row.closes!)}')
    .join('; ');

/// "Fri, Nov 21, 2026".
String formatDate(DateTime date) {
  final weekday = dayNames[(date.weekday - 1) % 7];
  return '$weekday, ${_months[date.month - 1]} ${date.day}, ${date.year}';
}

enum ScheduleKind { none, date, range, weekly }

/// What the owner picked for "When it happens".
class ScheduleChoice {
  const ScheduleChoice({
    this.kind = ScheduleKind.none,
    this.start,
    this.end,
    this.days = const {},
    this.time,
  });

  final ScheduleKind kind;
  final DateTime? start;
  final DateTime? end;
  final Set<int> days;

  /// Start time in minutes after midnight, optional.
  final int? time;

  bool get isComplete => switch (kind) {
    ScheduleKind.none => false,
    ScheduleKind.date => start != null,
    ScheduleKind.range => start != null && end != null && !end!.isBefore(start!),
    ScheduleKind.weekly => days.isNotEmpty,
  };
}

/// '' when the choice is not complete.
String formatSchedule(ScheduleChoice choice) {
  if (!choice.isComplete) return '';
  final at = choice.time == null ? '' : ' · ${formatClock(choice.time!)}';
  switch (choice.kind) {
    case ScheduleKind.date:
      return '${formatDate(choice.start!)}$at';
    case ScheduleKind.range:
      return '${formatDate(choice.start!)} to ${formatDate(choice.end!)}$at';
    case ScheduleKind.weekly:
      return 'Every ${formatDays(choice.days)}$at';
    case ScheduleKind.none:
      return '';
  }
}
