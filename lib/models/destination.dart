import 'home_section.dart';

class Destination {
  /// Stable catalog key used to join destinations, areas, and listings.
  final String id;

  /// User facing city, island, or destination name.
  final String name;
  final String country;
  final String countryCode;
  final String region;
  final String timezoneId;
  final String? parentDestinationId;
  final double? latitude;
  final double? longitude;
  final String flagEmoji;
  final String tagline;
  final String heroImageUrl;
  final List<String> areaIds;
  final List<HomeSection> homeSections;

  const Destination({
    required this.id,
    required this.name,
    required this.country,
    required this.countryCode,
    required this.region,
    required this.timezoneId,
    required this.flagEmoji,
    required this.tagline,
    required this.heroImageUrl,
    this.parentDestinationId,
    this.latitude,
    this.longitude,
    this.homeSections = const [],
    this.areaIds = const [],
  });
}
