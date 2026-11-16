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
  });

  final String id;
  final String title;
  final String description;
  final String category;
  final String subcategory;
  final String destinationId;
  final String destination;
  final String location;
  final String price;
  final String imageUrl;
  final String status;
  final String reviewNote;

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
    );
  }
}

String _requiredString(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('Business record.$key must be a non-empty string.');
  }
  return value;
}
