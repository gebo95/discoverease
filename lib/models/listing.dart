class Listing {
  final String title;
  final String subtitle;
  final String category;
  final String location;
  final String imageUrl;
  final double rating;
  final String price;
  final String status;
  final String? pulse;

  const Listing({
    required this.title,
    required this.subtitle,
    required this.category,
    required this.location,
    required this.imageUrl,
    required this.rating,
    required this.price,
    required this.status,
    this.pulse,
  });
}
