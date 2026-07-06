class SavedExperience {
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
}
