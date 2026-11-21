import '../shared/utils/photo_files.dart';
import '../shared/utils/web_link.dart';

class BusinessProfile {
  static const int schemaVersion = 1;

  const BusinessProfile({
    required this.id,
    required this.ownerUid,
    required this.name,
    required this.email,
    required this.phone,
    required this.website,
    required this.instagram,
    required this.status,
    required this.verified,
    required this.subscriptionTier,
  });

  final String id;
  final String ownerUid;
  final String name;
  final String email;
  final String phone;
  final String website;
  final String instagram;
  final String status;
  final bool verified;
  final String subscriptionTier;

  factory BusinessProfile.fromJson(Map<String, Object?> json) {
    return BusinessProfile(
      id: _requiredString(json, 'id'),
      ownerUid: _requiredString(json, 'ownerUid'),
      name: _requiredString(json, 'name'),
      email: _requiredString(json, 'email'),
      phone: json['phone'] as String? ?? '',
      website: json['website'] as String? ?? '',
      instagram: json['instagram'] as String? ?? '',
      status: json['status'] as String? ?? 'pending_review',
      verified: json['verified'] as bool? ?? false,
      subscriptionTier: json['subscriptionTier'] as String? ?? 'free',
    );
  }
}

class BusinessExperience {
  static const int schemaVersion = 1;

  const BusinessExperience({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.subcategory,
    required this.destinationId,
    required this.destination,
    required this.location,
    required this.price,
    required this.imageUrl,
    required this.status,
    this.reviewNote = '',
    this.address = '',
    this.website = '',
    this.bookingUrl = '',
    this.phone = '',
    this.hours = '',
    this.schedule = '',
    this.revision,
    this.revisionStatus = '',
    this.revisionNote = '',
    this.availability = 'live',
    this.availabilityMessage = '',
    this.endsAt,
    this.photos = const [],
  });

  final String id;
  final String title;
  final String description;
  final String category;
  final String subcategory;
  final String destinationId;
  final String destination;

  /// Photos, cover first. Entries are public web addresses once approved, or
  /// private upload paths while still waiting for review. [imageUrl] mirrors
  /// the cover once approved.
  final List<String> photos;

  /// 'live', 'hidden' (owner paused it) or 'ended' (its end date passed).
  /// Only meaningful once the experience is published; changed by a Cloud
  /// Function, never written by the app directly.
  final String availability;

  /// Optional note shown to travelers who saved a hidden experience.
  final String availabilityMessage;

  /// When the experience stops being offered, if it has an end date.
  final DateTime? endsAt;

  bool get isHidden => availability == 'hidden';
  bool get hasEnded => availability == 'ended';

  /// Area or neighborhood shown on cards (for example "Paradise Island").
  final String location;
  final String price;
  final String imageUrl;
  final String status;
  final String reviewNote;

  /// Optional details shown on the public listing once approved.
  final String address;
  final String website;
  final String bookingUrl;
  final String phone;

  /// Free text such as "Mon-Sat 9am-5pm".
  final String hours;

  /// Free text for when it happens, such as "Fri and Sat 8pm".
  final String schedule;

  /// Proposed changes to a live experience. The live fields above stay as
  /// they are (and stay visible to travelers) until an admin approves it.
  final ExperienceRevision? revision;

  /// '' when there is no proposed change, otherwise 'pending_review' or
  /// 'rejected'.
  final String revisionStatus;
  final String revisionNote;

  bool get hasPendingRevision =>
      revision != null && revisionStatus == 'pending_review';
  bool get hasRejectedRevision =>
      revision != null && revisionStatus == 'rejected';

  Map<String, Object?> toJson() => {
    'schemaVersion': schemaVersion,
    'id': id,
    'title': title,
    'description': description,
    'category': category,
    'subcategory': subcategory,
    'destinationId': destinationId,
    'destination': destination,
    'location': location,
    'price': price,
    'imageUrl': imageUrl,
    'status': status,
    'address': address,
    'website': website,
    'bookingUrl': bookingUrl,
    'phone': phone,
    'hours': hours,
    'schedule': schedule,
    'photos': photos,
  };

  factory BusinessExperience.fromJson(Map<String, Object?> json) {
    final version = (json['schemaVersion'] as num?)?.toInt() ?? 1;
    if (version != schemaVersion) {
      throw FormatException('Unsupported BusinessExperience schema: $version');
    }
    return BusinessExperience(
      id: _requiredString(json, 'id'),
      title: _requiredString(json, 'title'),
      description: json['description'] as String? ?? '',
      category: _requiredString(json, 'category'),
      subcategory: json['subcategory'] as String? ?? '',
      destinationId: _requiredString(json, 'destinationId'),
      destination: _requiredString(json, 'destination'),
      location: json['location'] as String? ?? '',
      price: json['price'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
      status: json['status'] as String? ?? 'pending_review',
      reviewNote: json['reviewNote'] as String? ?? '',
      address: json['address'] as String? ?? '',
      website: json['website'] as String? ?? '',
      bookingUrl: json['bookingUrl'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      hours: json['hours'] as String? ?? '',
      schedule: json['schedule'] as String? ?? '',
      revision: json['pendingRevision'] is Map
          ? ExperienceRevision.fromJson(
              Map<String, Object?>.from(json['pendingRevision'] as Map),
            )
          : null,
      revisionStatus: json['revisionStatus'] as String? ?? '',
      revisionNote: json['revisionNote'] as String? ?? '',
      availability: _availability(json['availability']),
      availabilityMessage: json['availabilityMessage'] as String? ?? '',
      endsAt: _dateTime(json['endsAt']),
      photos: _photoList(json['photos']),
    );
  }
}

List<String> _photoList(Object? value) =>
    value is List ? value.whereType<String>().toList(growable: false) : const [];

String _availability(Object? value) =>
    value == 'hidden' || value == 'ended' ? value! as String : 'live';

/// Reads a Firestore Timestamp (or a DateTime) without importing Firestore
/// into the model layer.
DateTime? _dateTime(Object? value) {
  if (value is DateTime) return value;
  if (value == null) return null;
  try {
    final converted = (value as dynamic).toDate();
    return converted is DateTime ? converted : null;
  } catch (_) {
    return null;
  }
}

/// One difference between the live experience and a proposed revision.
class RevisionChange {
  const RevisionChange({
    required this.label,
    required this.before,
    required this.after,
  });

  final String label;
  final String before;
  final String after;
}

/// The reviewable content of an experience. A business edits a live
/// experience by proposing one of these; it only replaces the live content
/// once an admin approves it.
class ExperienceRevision {
  const ExperienceRevision({
    required this.title,
    required this.description,
    required this.category,
    required this.subcategory,
    required this.destinationId,
    required this.destination,
    required this.location,
    required this.price,
    required this.imageUrl,
    this.address = '',
    this.website = '',
    this.bookingUrl = '',
    this.phone = '',
    this.hours = '',
    this.schedule = '',
    this.photos = const [],
  });

  factory ExperienceRevision.fromExperience(BusinessExperience experience) =>
      ExperienceRevision(
        title: experience.title,
        description: experience.description,
        category: experience.category,
        subcategory: experience.subcategory,
        destinationId: experience.destinationId,
        destination: experience.destination,
        location: experience.location,
        price: experience.price,
        imageUrl: experience.imageUrl,
        address: experience.address,
        website: experience.website,
        bookingUrl: experience.bookingUrl,
        phone: experience.phone,
        hours: experience.hours,
        schedule: experience.schedule,
        photos: experience.photos,
      );

  factory ExperienceRevision.fromJson(Map<String, Object?> json) {
    String text(String key) => json[key] as String? ?? '';
    return ExperienceRevision(
      title: text('title'),
      description: text('description'),
      category: text('category'),
      subcategory: text('subcategory'),
      destinationId: text('destinationId'),
      destination: text('destination'),
      location: text('location'),
      price: text('price'),
      imageUrl: text('imageUrl'),
      address: text('address'),
      website: text('website'),
      bookingUrl: text('bookingUrl'),
      phone: text('phone'),
      hours: text('hours'),
      schedule: text('schedule'),
      photos: _photoList(json['photos']),
    );
  }

  final String title;
  final String description;
  final String category;
  final String subcategory;
  final String destinationId;
  final String destination;
  final String location;
  final String price;
  final String imageUrl;
  final String address;
  final String website;
  final String bookingUrl;
  final String phone;
  final String hours;
  final String schedule;

  /// Proposed photos, cover first (see [BusinessExperience.photos]).
  final List<String> photos;

  Map<String, Object?> toJson() => {
    'title': title,
    'description': description,
    'category': category,
    'subcategory': subcategory,
    'destinationId': destinationId,
    'destination': destination,
    'location': location,
    'price': price,
    'imageUrl': imageUrl,
    'address': address,
    'website': website,
    'bookingUrl': bookingUrl,
    'phone': phone,
    'hours': hours,
    'schedule': schedule,
    'photos': photos,
  };

  /// Trimmed text with web links in their stored form, so comparing and
  /// saving never depends on stray spaces or a missing "https://".
  ExperienceRevision normalized() => ExperienceRevision(
    title: title.trim(),
    description: description.trim(),
    category: category.trim(),
    subcategory: subcategory.trim(),
    destinationId: destinationId.trim(),
    destination: destination.trim(),
    location: location.trim(),
    price: price.trim(),
    imageUrl: imageUrl.trim(),
    address: address.trim(),
    website: normalizeWebLink(website),
    bookingUrl: normalizeWebLink(bookingUrl),
    phone: phone.trim(),
    hours: hours.trim(),
    schedule: schedule.trim(),
    photos: photos,
  );

  /// What this revision would change on [live], in a form a reviewer can read.
  List<RevisionChange> changesFrom(BusinessExperience live) {
    final proposed = normalized();
    final current = ExperienceRevision.fromExperience(live).normalized();
    final changes = <RevisionChange>[];
    void compare(String label, String before, String after) {
      if (before != after) {
        changes.add(RevisionChange(label: label, before: before, after: after));
      }
    }

    compare('Name', current.title, proposed.title);
    compare('Description', current.description, proposed.description);
    compare('Category', current.category, proposed.category);
    compare('Type', current.subcategory, proposed.subcategory);
    compare('Destination', current.destination, proposed.destination);
    compare('Area', current.location, proposed.location);
    compare('Price', current.price, proposed.price);
    compare('Photo', current.imageUrl, proposed.imageUrl);
    compare('Street address', current.address, proposed.address);
    compare('Phone', current.phone, proposed.phone);
    compare('Website', current.website, proposed.website);
    compare('Booking link', current.bookingUrl, proposed.bookingUrl);
    compare('Hours', current.hours, proposed.hours);
    compare('Schedule', current.schedule, proposed.schedule);
    // Putting the same photos in a different order only changes the cover,
    // which needs no review, so only added or removed photos count.
    if (!samePhotoSet(current.photos, proposed.photos)) {
      final added = proposed.photos.where(isPendingPhoto).length;
      String count(int n) => n == 1 ? '1 photo' : '$n photos';
      changes.add(
        RevisionChange(
          label: 'Photos',
          before: count(current.photos.length),
          after:
              '${count(proposed.photos.length)}'
              '${added > 0 ? ' ($added new)' : ''}',
        ),
      );
    }
    return changes;
  }
}

String _requiredString(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('Business record.$key must be a non-empty string.');
  }
  return value;
}
