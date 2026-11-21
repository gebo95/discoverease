import 'package:discoverease/models/business_profile.dart';
import 'package:discoverease/models/listing.dart';
import 'package:discoverease/repositories/listing_repository.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, Object?> _notice({String reason = 'temporary', String message = ''}) => {
  'listingId': 'zz-test-cruise',
  'title': 'Sunset Cruise',
  'imageUrl': 'https://example.com/a.jpg',
  'destination': 'Bahamas',
  'destinationId': 'nassau',
  'category': 'Tours',
  'location': 'Paradise Island',
  'reason': reason,
  'message': message,
};

Map<String, Object?> _experience(Map<String, Object?> extra) => {
  'id': 'exp-1',
  'title': 'Sunset Cruise',
  'category': 'Tours',
  'destinationId': 'nassau',
  'destination': 'Bahamas',
  'status': 'published',
  ...extra,
};

void main() {
  group('ListingUnavailability', () {
    test('labels each reason in plain words', () {
      expect(const ListingUnavailability(reason: 'temporary').label, 'Temporarily unavailable');
      expect(const ListingUnavailability(reason: 'ended').label, 'Ended');
      expect(const ListingUnavailability(reason: 'removed').label, 'No longer available');
      expect(const ListingUnavailability(reason: 'anything else').label, 'No longer available');
    });

    test('includes the business note when there is one', () {
      const withNote = ListingUnavailability(reason: 'temporary', message: 'Back in spring');
      expect(withNote.explanation, contains('Back in spring'));
      const without = ListingUnavailability(reason: 'removed');
      expect(without.explanation, isNot(contains('They said')));
    });
  });

  group('placeholder listings', () {
    test('are built from the notice and carry the reason', () {
      final listing = Listing.fromUnavailableJson(_notice(message: 'Closed for repairs'));
      expect(listing.id, 'zz-test-cruise');
      expect(listing.title, 'Sunset Cruise');
      expect(listing.destinationId, 'nassau');
      expect(listing.isUnavailable, isTrue);
      expect(listing.unavailability!.message, 'Closed for repairs');
    });

    test('fall back to a generic title when the notice has none', () {
      final listing = Listing.fromUnavailableJson({..._notice(), 'title': ''});
      expect(listing.title, 'Experience');
    });

    test('are found by id but never appear in search or browsing', () {
      final repository = ListingRepository();
      repository.setUnavailableListings([Listing.fromUnavailableJson(_notice())]);

      expect(repository.getById('zz-test-cruise')?.isUnavailable, isTrue);
      expect(repository.getAll().any((l) => l.id == 'zz-test-cruise'), isFalse);
      expect(repository.getForDestination('nassau').any((l) => l.id == 'zz-test-cruise'), isFalse);
    });

    test('a live listing wins over a stale notice', () {
      final repository = ListingRepository();
      repository.setUnavailableListings([Listing.fromUnavailableJson(_notice())]);
      repository.setPublishedListings([
        Listing.fromCatalogJson({
          'id': 'zz-test-cruise',
          'title': 'Sunset Cruise',
          'category': 'Tours',
          'destinationId': 'nassau',
          'destination': 'Bahamas',
          'status': 'published',
        }),
      ]);
      expect(repository.getById('zz-test-cruise')?.isUnavailable, isFalse);
    });

    test('are forgotten once the notice is cleared', () {
      final repository = ListingRepository();
      repository.setUnavailableListings([Listing.fromUnavailableJson(_notice())]);
      repository.setUnavailableListings(const []);
      expect(repository.getById('zz-test-cruise'), isNull);
    });
  });

  group('business experience availability', () {
    test('defaults to live when nothing is stored', () {
      final experience = BusinessExperience.fromJson(_experience({}));
      expect(experience.availability, 'live');
      expect(experience.isHidden, isFalse);
      expect(experience.hasEnded, isFalse);
      expect(experience.endsAt, isNull);
    });

    test('reads hidden, ended, the note and the end date', () {
      final endsAt = DateTime.utc(2026, 12, 1);
      final hidden = BusinessExperience.fromJson(
        _experience({'availability': 'hidden', 'availabilityMessage': 'Back soon', 'endsAt': endsAt}),
      );
      expect(hidden.isHidden, isTrue);
      expect(hidden.availabilityMessage, 'Back soon');
      expect(hidden.endsAt, endsAt);
      expect(BusinessExperience.fromJson(_experience({'availability': 'ended'})).hasEnded, isTrue);
    });

    test('treats an unknown value as live', () {
      expect(BusinessExperience.fromJson(_experience({'availability': 'weird'})).availability, 'live');
    });
  });
}
