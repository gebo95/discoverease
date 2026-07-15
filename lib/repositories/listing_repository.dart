import '../mock_data/listings/live_now.dart';
import '../models/listing.dart';

class ListingRepository {
  const ListingRepository();

  List<Listing> getAll() {
    return List.unmodifiable(liveNowListings);
  }

  List<Listing> getForDestination(String destination) {
    final normalizedDestination = destination.trim().toLowerCase();

    return getAll()
        .where(
          (listing) =>
              listing.destination.trim().toLowerCase() == normalizedDestination,
        )
        .toList();
  }

  List<Listing> searchListings(
    String destination,
    String query, {
    String? filter,
  }) {
    final filteredListings = getFiltered(destination, filter);

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

  List<Listing> getByCategory(String destination, String category) {
    final normalizedCategory = category.trim().toLowerCase();

    return getForDestination(destination).where((listing) {
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

  List<Listing> getLiveNow(String destination) {
    return getForDestination(
      destination,
    ).where((listing) => (listing.pulse ?? "").isNotEmpty).toList();
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

  List<Listing> getFiltered(String destination, String? filter) {
    final listings = getForDestination(destination);

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
      return liveNowListings.firstWhere((listing) => listing.id == id);
    } catch (_) {
      return null;
    }
  }
}
