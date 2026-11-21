import 'package:flutter/foundation.dart';

import '../mock_data/listings/live_now.dart';
import '../models/listing.dart';

class ListingRepository extends ChangeNotifier {
  ListingRepository();

  List<Listing> _published = const [];
  Map<String, Listing> _unavailable = const {};

  /// Replaces only the remote published records; local curated listings remain.
  void setPublishedListings(Iterable<Listing> listings) {
    _published = List.unmodifiable(listings);
    notifyListeners();
  }

  /// Stand-ins for listings that travelers saved or planned but that are no
  /// longer public. They are found by [getById] only and never appear in
  /// search, browsing or recommendations.
  void setUnavailableListings(Iterable<Listing> listings) {
    _unavailable = Map.unmodifiable({
      for (final listing in listings) listing.id: listing,
    });
    notifyListeners();
  }

  List<Listing> getAll() {
    final merged = <String, Listing>{
      for (final listing in liveNowListings) listing.id: listing,
      for (final listing in _published) listing.id: listing,
    };
    return List.unmodifiable(merged.values);
  }

  List<Listing> getForDestination(String destinationIdOrCountry) {
    final normalizedDestination = destinationIdOrCountry.trim().toLowerCase();

    return getAll()
        .where(
          (listing) =>
              listing.destinationId.trim().toLowerCase() ==
                  normalizedDestination ||
              listing.destination.trim().toLowerCase() == normalizedDestination,
        )
        .toList();
  }

  List<Listing> getForArea(String destinationId, String areaId) {
    return getForDestination(destinationId)
        .where((listing) => listing.areaId == areaId)
        .toList();
  }

  List<Listing> searchListings(
    String destination,
    String query, {
    String? filter,
    String? areaId,
  }) {
    final filteredListings = getFiltered(
      destination,
      filter,
      areaId: areaId,
    );

    final normalizedQuery = query.trim().toLowerCase();

    if (normalizedQuery.isEmpty) {
      return filteredListings;
    }

    return filteredListings.where((listing) {
      return listing.title.toLowerCase().contains(normalizedQuery) ||
          listing.subtitle.toLowerCase().contains(normalizedQuery) ||
          listing.category.toLowerCase().contains(normalizedQuery) ||
          listing.subcategory.toLowerCase().contains(normalizedQuery) ||
          listing.destination.toLowerCase().contains(normalizedQuery) ||
          listing.location.toLowerCase().contains(normalizedQuery) ||
          listing.features.any(
            (feature) => feature.toLowerCase().contains(normalizedQuery),
          ) ||
          listing.perfectFor.any(
            (value) => value.toLowerCase().contains(normalizedQuery),
          );
    }).toList();
  }

  List<Listing> getByCategory(
    String destination,
    String category, {
    String? areaId,
  }) {
    final normalizedCategory = category.trim().toLowerCase();

    final listings = areaId == null
        ? getForDestination(destination)
        : getForArea(destination, areaId);
    return listings.where((listing) {
      final listingCategory = listing.category.toLowerCase();
      final listingSubcategory = listing.subcategory.toLowerCase();
      final listingFeatures = listing.features.map(
        (feature) => feature.toLowerCase(),
      );

      return listingCategory.contains(normalizedCategory) ||
          listingSubcategory.contains(normalizedCategory) ||
          listingFeatures.any(
            (feature) => feature.contains(normalizedCategory),
          );
    }).toList();
  }

  List<Listing> getLiveNow(String destination, {String? areaId}) {
    final listings = areaId == null
        ? getForDestination(destination)
        : getForArea(destination, areaId);
    return listings
        .where((listing) => (listing.pulse ?? '').isNotEmpty)
        .toList();
  }

  List<Listing> getDining(String destination) {
    return getForDestination(destination)
        .where(
          (listing) =>
              listing.category.contains("Dining") ||
              listing.subcategory.toLowerCase().contains("food") ||
              listing.features.contains("Local Favorite"),
        )
        .toList();
  }

  List<Listing> getBeaches(String destination) {
    return getForDestination(destination)
        .where(
          (listing) =>
              listing.subcategory.toLowerCase().contains("beach") ||
              listing.features.contains("Ocean View"),
        )
        .toList();
  }

  List<Listing> getLiveMusic(String destination) {
    return getForDestination(destination)
        .where(
          (listing) =>
              listing.category.contains("Live Music") ||
              listing.features.contains("Live Music"),
        )
        .toList();
  }

  List<Listing> getTours(String destination) {
    return getForDestination(destination)
        .where(
          (listing) =>
              listing.category.contains("Tour") ||
              listing.subcategory.toLowerCase().contains("tour"),
        )
        .toList();
  }

  List<Listing> getShopping(String destination) {
    return getForDestination(destination)
        .where(
          (listing) =>
              listing.category.contains("Shopping") ||
              listing.subcategory.toLowerCase().contains("shop"),
        )
        .toList();
  }

  List<Listing> getHiddenGems(String destination) {
    return getForDestination(
      destination,
    ).where((listing) => listing.features.contains("Hidden Gem")).toList();
  }

  List<Listing> getFiltered(
    String destination,
    String? filter, {
    String? areaId,
  }) {
    final listings = areaId == null
        ? getForDestination(destination)
        : getForArea(destination, areaId);

    if (filter == null) {
      return listings;
    }

    switch (filter) {
      case "❤️ Romantic":
        return listings
            .where(
              (listing) =>
                  listing.perfectFor.contains("Couples") ||
                  listing.perfectFor.contains("Date Night"),
            )
            .toList();

      case "🍽 Hungry":
        return listings
            .where(
              (listing) =>
                  listing.category.contains("Dining") ||
                  listing.features.contains("Local Favorite"),
            )
            .toList();

      case "🎵 Live Music":
        return listings
            .where(
              (listing) =>
                  listing.category.contains("Live Music") ||
                  listing.features.contains("Live Music"),
            )
            .toList();

      case "🏖 Beach":
        return listings
            .where(
              (listing) =>
                  listing.subcategory.contains("Beach") ||
                  listing.features.contains("Ocean View"),
            )
            .toList();

      case "👨‍👩‍👧 Family":
        return listings
            .where(
              (listing) =>
                  listing.perfectFor.contains("Family") ||
                  listing.perfectFor.contains("Families"),
            )
            .toList();

      case "✨ Hidden Gems":
        return listings
            .where((listing) => listing.features.contains("Hidden Gem"))
            .toList();

      case "🌅 Sunset":
        return listings
            .where(
              (listing) =>
                  listing.perfectFor.contains("Sunset") ||
                  listing.subtitle.toLowerCase().contains("sunset"),
            )
            .toList();

      case "💰 Budget":
        return listings
            .where((listing) => listing.price == r"$" || listing.price == r"$$")
            .toList();

      default:
        return listings;
    }
  }

  Listing? getById(String id) {
    try {
      return getAll().firstWhere((listing) => listing.id == id);
    } catch (_) {
      return _unavailable[id];
    }
  }
}
