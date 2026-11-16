import 'package:flutter_test/flutter_test.dart';
import 'package:discoverease/features/trips/pages/trip_saved_filter.dart';
import 'package:discoverease/mock_data/saved/mock_saved.dart';
import 'package:discoverease/mock_data/trips/mock_trips.dart';
import 'package:discoverease/models/saved_experience.dart';
import 'package:discoverease/repositories/listing_repository.dart';

void main() {
  test('matches saved listings by stable destination ID and omits planned items', () {
    final listings = ListingRepository();
    final saved = [
      ...mockSavedExperiences,
      const SavedExperience(
        id: 'saved-unknown',
        listingId: 'missing-listing',
        destination: 'Bahamas',
      ),
    ];

    final result = TripSavedFilter.forTrip(
      trip: currentTrip,
      saved: saved,
      listings: listings,
      isPlanned: (listingId) => listingId == 'sunset-cruise',
    );

    expect(result.map((item) => item.listingId), contains('arawak-cay-fish-fry'));
    expect(result.map((item) => item.listingId), isNot(contains('sunset-cruise')));
    expect(result.map((item) => item.listingId), isNot(contains('missing-listing')));
    listings.dispose();
  });
}
