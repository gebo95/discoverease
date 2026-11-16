import 'review.dart';

class Listing {
  final String id;
  final String title;
  final String subtitle;
  final String category;
  final String subcategory;
  /// Stable key linking this listing to a Destination catalog record.
  final String destinationId;
  /// Kept as a display/legacy field for existing trip and content surfaces.
  final String destination;
  /// Stable key for the listing's primary destination area, when known.
  final String? areaId;
  /// Set only for catalog items submitted by a business.
  final String? businessId;
  final String location;
  final String imageUrl;
  final List<String> gallery;
  /// Null means no verified reviews exist yet. Never show a synthetic rating.
  final double? rating;
  final int reviewCount;
  final String price;
  final String status;
  final String description;
  final String whyYoullLoveIt;
  final List<String> perfectFor;
  final List<String> features;
  final List<String> pairedListingIds;
  final List<String> continueDayIds;
  final List<Review> reviews;
  final String? pulse;

  const Listing({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.category,
    required this.subcategory,
    required this.destinationId,
    required this.destination,
    this.areaId,
    this.businessId,
    required this.location,
    required this.imageUrl,
    this.gallery = const [],
    this.pairedListingIds = const [],
    required this.rating,
    this.reviewCount = 0,
    required this.price,
    required this.status,
    required this.description,
    required this.whyYoullLoveIt,
    this.perfectFor = const [],
    this.features = const [],
    this.continueDayIds = const [],
    this.reviews = const [],
    this.pulse,
  });

  factory Listing.fromCatalogJson(Map<String, Object?> json) {
    String value(String key) => json[key] is String ? json[key] as String : '';
    List<String> strings(String key) {
      final raw = json[key];
      if (raw is! List) return const [];
      return raw.whereType<String>().toList(growable: false);
    }

    final rawAreaId = json['areaId'];
    final rawRating = json['rating'];
    final rawBusinessId = json['businessId'];

    return Listing(
      id: value('id'),
      title: value('title'),
      subtitle: value('subtitle'),
      category: value('category'),
      subcategory: value('subcategory'),
      destinationId: value('destinationId'),
      destination: value('destination'),
      areaId: rawAreaId is String ? rawAreaId : null,
      businessId: rawBusinessId is String ? rawBusinessId : null,
      location: value('location'),
      imageUrl: value('imageUrl'),
      gallery: strings('gallery'),
      rating: rawRating is num ? rawRating.toDouble() : null,
      reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
      price: value('price'),
      status: value('displayStatus').isNotEmpty
          ? value('displayStatus')
          : value('status'),
      description: value('description'),
      whyYoullLoveIt: value('whyYoullLoveIt'),
      perfectFor: strings('perfectFor'),
      features: strings('features'),
      pairedListingIds: strings('pairedListingIds'),
      continueDayIds: strings('continueDayIds'),
    );
  }
}
