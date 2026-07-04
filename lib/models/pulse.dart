class Pulse {
  final String id;
  final String listingId;
  final String title;
  final String message;
  final String type;
  final DateTime createdAt;
  final DateTime expiresAt;

  const Pulse({
    required this.id,
    required this.listingId,
    required this.title,
    required this.message,
    required this.type,
    required this.createdAt,
    required this.expiresAt,
  });
}
