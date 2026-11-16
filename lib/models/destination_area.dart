class DestinationArea {
  final String id;
  final String destinationId;
  final String name;
  final String imageUrl;
  final String? subtitle;

  const DestinationArea({
    required this.id,
    required this.destinationId,
    required this.name,
    required this.imageUrl,
    this.subtitle,
  });
}
