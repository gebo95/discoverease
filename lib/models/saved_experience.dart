class SavedExperience {
  static const int schemaVersion = 1;
  final String id;

  final String listingId;

  final String destination;

  final String? listName;

  const SavedExperience({
    required this.id,
    required this.listingId,
    required this.destination,
    this.listName,
  });

  Map<String, Object?> toJson() => {
    'schemaVersion': schemaVersion,
    'id': id,
    'listingId': listingId,
    'destination': destination,
    'listName': listName,
  };

  factory SavedExperience.fromJson(Map<String, Object?> json) {
    final version = (json['schemaVersion'] as num?)?.toInt() ?? 1;
    if (version != schemaVersion) {
      throw FormatException('Unsupported SavedExperience schema version: $version');
    }
    String requiredString(String key) {
      final value = json[key];
      if (value is! String || value.isEmpty) {
        throw FormatException('SavedExperience.$key must be a non-empty string.');
      }
      return value;
    }

    return SavedExperience(
      id: requiredString('id'),
      listingId: requiredString('listingId'),
      destination: requiredString('destination'),
      listName: json['listName'] as String?,
    );
  }
}
