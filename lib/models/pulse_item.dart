enum PulseType { liveNow, startingSoon, endingSoon, trending }

class PulseItem {
  final String id;
  final String listingId;
  final String title;
  final String message;
  final String timeLabel;
  final PulseType type;
  final bool isRead;

  const PulseItem({
    required this.id,
    required this.listingId,
    required this.title,
    required this.message,
    required this.timeLabel,
    required this.type,
    this.isRead = false,
  });
}
