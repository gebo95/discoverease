import '../mock_data/listings/live_now.dart';
import '../models/listing.dart';

class ListingRepository {
  const ListingRepository();

  List<Listing> searchListings(String query, {String? filter}) {
    final filteredListings = getFiltered(filter);
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

  List<Listing> getFiltered(String? filter) {
    final listings = getLiveNow();

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

  List<Listing> getLiveNow() {
    return liveNowListings;
  }

  Listing? getById(String id) {
    try {
      return liveNowListings.firstWhere((listing) => listing.id == id);
    } catch (_) {
      return null;
    }
  }
}
