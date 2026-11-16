import '../../../models/listing.dart';
import '../../../models/saved_experience.dart';
import '../../../repositories/destination_repository.dart';
import '../../../repositories/listing_repository.dart';

class SavedCountryGroup {
  final String name;
  final List<SavedAreaGroup> areas;
  final int count;

  const SavedCountryGroup({
    required this.name,
    required this.areas,
    required this.count,
  });
}

class SavedAreaGroup {
  final String name;
  final List<SavedCategoryGroup> categories;
  final int count;

  /// Cover photo for the area: the destination area's own image when known,
  /// otherwise the first saved listing's photo. Empty if neither exists.
  final String imageUrl;

  const SavedAreaGroup({
    required this.name,
    required this.categories,
    required this.count,
    this.imageUrl = '',
  });
}

class SavedCategoryGroup {
  final String name;
  final List<Listing> listings;

  const SavedCategoryGroup({required this.name, required this.listings});
}

class SavedGroupBuilder {
  const SavedGroupBuilder._();

  static List<SavedCountryGroup> build({
    required List<SavedExperience> saved,
    required ListingRepository listings,
    required DestinationRepository destinations,
  }) {
    final tree = <String, Map<String, Map<String, List<Listing>>>>{};
    final displayCountry = <String, String>{};
    final displayArea = <String, String>{};
    final areaImage = <String, String>{};
    final seenListingIds = <String>{};

    for (final save in saved) {
      if (!seenListingIds.add(save.listingId)) continue;
      final listing = listings.getById(save.listingId);
      if (listing == null) continue;

      final destination = destinations.getById(listing.destinationId);
      final area = listing.areaId == null
          ? null
          : destinations.getAreaById(listing.areaId!);
      final country = _nonEmpty(destination?.country) ??
          _nonEmpty(save.destination) ??
          _nonEmpty(listing.destination) ??
          'Other destinations';
      final areaName = _nonEmpty(area?.name) ??
          (listing.areaId == null ? null : _nonEmpty(listing.location)) ??
          _nonEmpty(destination?.name) ??
          _nonEmpty(listing.destination) ??
          'Other areas';
      final categoryName = _displayCategory(listing.category);
      final countryKey = country.trim().toLowerCase();
      final areaKey = areaName.trim().toLowerCase();

      displayCountry.putIfAbsent(countryKey, () => country);
      displayArea.putIfAbsent('$countryKey/$areaKey', () => areaName);
      final imageKey = '$countryKey/$areaKey';
      final imageCandidate =
          _nonEmpty(area?.imageUrl) ?? _nonEmpty(listing.imageUrl);
      if (imageCandidate != null && (areaImage[imageKey] ?? '').isEmpty) {
        areaImage[imageKey] = imageCandidate;
      }
      tree
          .putIfAbsent(countryKey, () => {})
          .putIfAbsent(areaKey, () => {})
          .putIfAbsent(categoryName, () => [])
          .add(listing);
    }

    final groups = tree.entries.map((countryEntry) {
      var countryCount = 0;
      final areas = countryEntry.value.entries.map((areaEntry) {
        var areaCount = 0;
        final categories = areaEntry.value.entries.map((categoryEntry) {
          final items = [...categoryEntry.value]
            ..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
          areaCount += items.length;
          return SavedCategoryGroup(name: categoryEntry.key, listings: items);
        }).toList()
          ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        countryCount += areaCount;
        return SavedAreaGroup(
          name: displayArea['${countryEntry.key}/${areaEntry.key}'] ?? areaEntry.key,
          categories: categories,
          count: areaCount,
          imageUrl: areaImage['${countryEntry.key}/${areaEntry.key}'] ?? '',
        );
      }).toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return SavedCountryGroup(
        name: displayCountry[countryEntry.key] ?? countryEntry.key,
        areas: areas,
        count: countryCount,
      );
    }).toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    return groups;
  }

  static String _displayCategory(String rawCategory) {
    final value = rawCategory
        .replaceFirst(RegExp(r'^[^A-Za-z0-9]+'), '')
        .trim();
    final lower = value.toLowerCase();
    if (lower.contains('tour')) return 'Tours';
    if (lower.contains('dining') ||
        lower.contains('food') ||
        lower.contains('restaurant') ||
        lower.contains('cuisine') ||
        lower.contains('coffee') ||
        lower.contains('cafe')) {
      return 'Food';
    }
    if (lower.contains('nightlife') ||
        lower.contains('club') ||
        lower.contains('live music')) {
      return 'Clubs & Nightlife';
    }
    return value.isEmpty ? 'Other experiences' : value;
  }

  static String? _nonEmpty(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}
