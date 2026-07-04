class SavedList {
  final String id;
  final String title;
  final String destination;
  final List<String> listingIds;
  final bool isDefaultUnsorted;

  const SavedList({
    required this.id,
    required this.title,
    required this.destination,
    this.listingIds = const [],
    this.isDefaultUnsorted = false,
  });
}
