import '../mock_data/listings/live_now.dart';
import '../models/listing.dart';

class ListingRepository {
  const ListingRepository();

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
