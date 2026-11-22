/// A short, timely update a business posts on one of its listings, such as
/// "Live Music" or "Happy Hour 4 to 6". Not to be confused with the trip
/// reminders shown on the Pulse page ([PulseItem]).
///
/// The tag and duration lists are mirrored in functions/pulse_logic.js, which
/// is what actually enforces them.
library;

const int businessPulseMessageMax = 100;

const List<String> businessPulseTags = [
  'Live Music',
  'Happy Hour',
  'Daily Special',
  'Event Tonight',
  'Limited Time',
  'Now Open',
  'Open Late',
  'Sunset Special',
  'Family Day',
  'Free Entry',
];

/// How long a post stays up, in hours.
const List<int> businessPulseHours = [3, 6, 12, 24, 72, 168];

String pulseDurationLabel(int hours) =>
    hours < 24 ? '$hours hours' : hours == 24 ? '1 day' : '${hours ~/ 24} days';

class BusinessPulse {
  const BusinessPulse({
    required this.listingId,
    required this.businessId,
    required this.destinationId,
    required this.title,
    required this.tag,
    required this.expiresAt,
    this.message = '',
    this.category = '',
    this.imageUrl = '',
    this.startsAt,
  });

  final String listingId;
  final String businessId;
  final String destinationId;
  final String title;
  final String category;
  final String imageUrl;
  final String tag;
  final String message;
  final DateTime? startsAt;
  final DateTime expiresAt;

  bool isActive(DateTime now) => expiresAt.isAfter(now);

  /// A key that changes whenever the business posts a new Pulse, so a
  /// traveler is shown each new post once.
  String get postKey => '$listingId:${startsAt?.millisecondsSinceEpoch ?? expiresAt.millisecondsSinceEpoch}';

  /// "Until 9:00 PM" today, "Until Sat 9:00 PM" later, in the viewer's time.
  String untilLabel(DateTime now) {
    final end = expiresAt.toLocal();
    final hour12 = end.hour % 12 == 0 ? 12 : end.hour % 12;
    final clock =
        '$hour12:${end.minute.toString().padLeft(2, '0')} ${end.hour < 12 ? 'AM' : 'PM'}';
    final today = DateTime(now.year, now.month, now.day);
    final endDay = DateTime(end.year, end.month, end.day);
    if (endDay == today) return 'Until $clock';
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return 'Until ${days[end.weekday - 1]} $clock';
  }

  /// Null when the data is not a usable post.
  static BusinessPulse? fromJson(Map<String, Object?> json) {
    final listingId = json['listingId'];
    final tag = json['tag'];
    final expires = _date(json['expiresAt']);
    if (listingId is! String || listingId.isEmpty) return null;
    if (tag is! String || tag.isEmpty || expires == null) return null;
    String text(String key) => json[key] is String ? json[key]! as String : '';
    return BusinessPulse(
      listingId: listingId,
      businessId: text('businessId'),
      destinationId: text('destinationId'),
      title: text('title'),
      category: text('category'),
      imageUrl: text('imageUrl'),
      tag: tag,
      message: text('message'),
      startsAt: _date(json['startsAt']),
      expiresAt: expires,
    );
  }
}

/// Reads a Firestore Timestamp (or DateTime) without importing Firestore.
DateTime? _date(Object? value) {
  if (value is DateTime) return value;
  if (value == null) return null;
  try {
    final converted = (value as dynamic).toDate();
    return converted is DateTime ? converted : null;
  } catch (_) {
    return null;
  }
}
