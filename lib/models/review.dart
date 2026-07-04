class Review {
  final String id;
  final String listingId;
  final String userName;
  final double rating;
  final String comment;
  final DateTime createdAt;

  const Review({
    required this.id,
    required this.listingId,
    required this.userName,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });
}
