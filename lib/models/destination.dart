import 'home_section.dart';

class Destination {
  final String id;
  final String name;
  final String country;
  final String flagEmoji;
  final String atmosphereMessage;
  final String heroImageUrl;
  final List<String> areaIds;
  final List<HomeSection> homeSections;

  const Destination({
    required this.id,
    required this.name,
    required this.country,
    required this.flagEmoji,
    required this.atmosphereMessage,
    required this.heroImageUrl,
    this.homeSections = const [],
    this.areaIds = const [],
  });
}
