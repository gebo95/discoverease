enum PulseType {
  reservation,
  departure,
  startingSoon,
  liveNow,
  endingSoon,
  trending,
}

class PulseItem {
  final String id;
  final String listingId;
  final String title;
  final String message;
  final String timeLabel;
  final PulseType type;
  final bool isRead;
  final DateTime? scheduledAt;
  final String? experienceId;
  final int? dayIndex;
  final String? tripDayTitle;

  const PulseItem({
    required this.id,
    required this.listingId,
    required this.title,
    required this.message,
    required this.timeLabel,
    required this.type,
    this.isRead = false,
    this.scheduledAt,
    this.experienceId,
    this.dayIndex,
    this.tripDayTitle,
  });
}
