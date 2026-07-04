class Listing {
  final String id;
  final String title;
  final String subtitle;
  final String category;
  final String subcategory;
  final String destination;
  final String location;
  final String imageUrl;
  final List<String> gallery;
  final double rating;
  final int reviewCount;
  final String price;
  final String status;
  final String description;
  final String whyYoullLoveIt;
  final List<String> perfectFor;
  final List<String> features;
  final String? pulse;

  const Listing({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.category,
    required this.subcategory,
    required this.destination,
    required this.location,
    required this.imageUrl,
    this.gallery = const [],
    required this.rating,
    this.reviewCount = 0,
    required this.price,
    required this.status,
    required this.description,
    required this.whyYoullLoveIt,
    this.perfectFor = const [],
    this.features = const [],
    this.pulse,
  });
}
