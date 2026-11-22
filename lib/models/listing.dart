import 'review.dart';

/// Why a listing travelers saved is no longer being offered. Built from the
/// small public notice a Cloud Function leaves behind.
class ListingUnavailability {
  const ListingUnavailability({required this.reason, this.message = ''});

  /// 'temporary' (hidden for now), 'removed' (deleted) or 'ended'.
  final String reason;

  /// Optional note from the business, empty if they left none.
  final String message;

  bool get isTemporary => reason == 'temporary';

  /// Short label for cards and banners.
  String get label => switch (reason) {
    'temporary' => 'Temporarily unavailable',
    'ended' => 'Ended',
    _ => 'No longer available',
  };

  /// One sentence of explanation, including the business's note if present.
  String get explanation {
    final base = switch (reason) {
      'temporary' =>
        'The business has paused this experience. It may come back, and it will '
            'return to your saved places if it does.',
      'ended' => 'This experience has finished.',
      _ => 'The business has removed this experience.',
    };
    return message.isEmpty ? base : '$base They said: "$message"';
  }
}

/// How long a listing wears the automatic "New" tag after approval.
const Duration newListingWindow = Duration(days: 14);

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
  /// Optional business-provided details, empty when not supplied.
  final String address;
  /// Optional map pin set by the business, for directions.
  final double? latitude;
  final double? longitude;
  final String website;
  final String bookingUrl;
  final String phone;
  final String hours;
  final String schedule;
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

  /// Set only for a placeholder standing in for a listing that travelers saved
  /// or planned but that is no longer offered. Normal listings leave it null.
  final ListingUnavailability? unavailability;

  /// When the business says this stops being offered, if it has an end date.
  final DateTime? endsAt;

  /// "Dec 1, 2026" style date used on cards and warnings.
  static String shortDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final local = date.toLocal();
    return '${months[local.month - 1]} ${local.day}, ${local.year}';
  }

  /// A heads-up for planning this on [dayDate], or null if there is nothing
  /// to flag. A day after the end date gets a firm warning; with no date set
  /// yet the traveler is just reminded to check. Adding is always allowed,
  /// because trip dates are often not final.
  String? endWarning({DateTime? dayDate}) {
    final end = endsAt;
    if (end == null) return null;
    final endLocal = end.toLocal();
    final endDay = DateTime(endLocal.year, endLocal.month, endLocal.day);
    final text = shortDate(end);
    if (dayDate == null) {
      return 'This ends on $text. Check that it is still running on the '
          'day you go.';
    }
    final day = DateTime(dayDate.year, dayDate.month, dayDate.day);
    if (day.isAfter(endDay)) {
      return 'This ends on $text, before this day of your trip. You can still '
          'add it in case your dates change.';
    }
    return null;
  }

  bool get isUnavailable => unavailability != null;

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
    this.address = '',
    this.latitude,
    this.longitude,
    this.website = '',
    this.bookingUrl = '',
    this.phone = '',
    this.hours = '',
    this.schedule = '',
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
    this.unavailability,
    this.endsAt,
  });

  /// A stand-in for a listing that is no longer public, built from its
  /// `unavailable` notice so saved places and trips can still show it.
  factory Listing.fromUnavailableJson(Map<String, Object?> json) {
    String value(String key) => json[key] is String ? json[key] as String : '';
    final rawAreaId = json['areaId'];
    return Listing(
      id: value('listingId'),
      title: value('title').isEmpty ? 'Experience' : value('title'),
      subtitle: '',
      category: value('category'),
      subcategory: value('subcategory'),
      destinationId: value('destinationId'),
      destination: value('destination'),
      areaId: rawAreaId is String ? rawAreaId : null,
      location: value('location'),
      imageUrl: value('imageUrl'),
      rating: null,
      price: '',
      status: 'Unavailable',
      description: '',
      whyYoullLoveIt: '',
      unavailability: ListingUnavailability(
        reason: value('reason'),
        message: value('message'),
      ),
    );
  }

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
    final endsAt = _asDateTime(json['endsAt']);
    // "New" is automatic when a listing is approved and wears off after two
    // weeks. Nothing replaces it, so the card just shows no tag.
    final publishedAt = _asDateTime(json['publishedAt']);
    final isStaleNew =
        value('displayStatus') == 'New' &&
        publishedAt != null &&
        DateTime.now().difference(publishedAt) > newListingWindow;
    // The tag on the card: an end date first, then the owner's highlight,
    // then the automatic "New".
    final highlight = value('highlight').trim();
    final displayStatus = endsAt != null && endsAt.isAfter(DateTime.now())
        ? 'Ends ${shortDate(endsAt)}'
        : highlight.isNotEmpty
        ? highlight
        : isStaleNew
        ? ''
        : value('displayStatus');

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
      address: value('address'),
      latitude: _coordinate(json['latitude'], 90),
      longitude: _coordinate(json['longitude'], 180),
      website: value('website'),
      bookingUrl: value('bookingUrl'),
      phone: value('phone'),
      hours: value('hours'),
      schedule: value('schedule'),
      imageUrl: value('imageUrl'),
      gallery: strings('gallery'),
      rating: rawRating is num ? rawRating.toDouble() : null,
      reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
      price: value('price'),
      endsAt: endsAt,
      status: displayStatus.isNotEmpty
          ? displayStatus
          : isStaleNew
          ? ''
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

/// A coordinate within +/- [limit], or null.
double? _coordinate(Object? value, double limit) {
  if (value is! num) return null;
  final number = value.toDouble();
  return number.abs() <= limit ? number : null;
}

/// Reads a Firestore Timestamp (or DateTime) without importing Firestore here.
DateTime? _asDateTime(Object? value) {
  if (value is DateTime) return value;
  if (value == null) return null;
  try {
    final converted = (value as dynamic).toDate();
    return converted is DateTime ? converted : null;
  } catch (_) {
    return null;
  }
}
