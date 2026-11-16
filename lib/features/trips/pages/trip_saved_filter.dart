import '../../../models/saved_experience.dart';
import '../../../models/trip.dart';
import '../../../repositories/listing_repository.dart';

class TripSavedFilter {
  const TripSavedFilter._();

  static List<SavedExperience> forTrip({
    required Trip trip,
    required List<SavedExperience> saved,
    required ListingRepository listings,
    required bool Function(String listingId) isPlanned,
    bool includePlanned = false,
  }) {
    return saved.where((item) {
      final listing = listings.getById(item.listingId);
      if (listing == null || (!includePlanned && isPlanned(item.listingId))) {
        return false;
      }
      final matchesId = trip.destinationId != null &&
          listing.destinationId == trip.destinationId;
      final tripName = trip.destination.trim().toLowerCase();
      final matchesName = listing.destination.trim().toLowerCase() == tripName ||
          item.destination.trim().toLowerCase() == tripName;
      return matchesId || matchesName;
    }).toList(growable: false);
  }
}
