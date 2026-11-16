import 'package:discoverease/models/listing.dart';
import 'package:discoverease/repositories/listing_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('published listing catalog', () {
    test('maps a business experience without inventing review data', () {
      final listing = Listing.fromCatalogJson({
        'id': 'experience-1',
        'title': 'Harbor walk',
        'subtitle': 'Downtown',
        'category': 'Tours',
        'subcategory': 'Walking',
        'destinationId': 'nassau',
        'destination': 'Nassau',
        'location': 'Downtown Nassau',
        'price': r'$$',
        'status': 'published',
        'description': 'A guided harbor walk.',
        'rating': null,
        'reviewCount': 0,
      });

      expect(listing.rating, isNull);
      expect(listing.reviewCount, 0);
      expect(listing.destinationId, 'nassau');
    });

    test('merges published records with curated listings for search and lookup', () {
      final repository = ListingRepository();
      final listing = Listing.fromCatalogJson({
        'id': 'business-harbor-walk',
        'title': 'Harbor walk',
        'subtitle': 'Downtown Nassau',
        'category': 'Tours',
        'subcategory': 'Walking',
        'destinationId': 'nassau',
        'destination': 'Nassau',
        'location': 'Downtown',
        'price': r'$$',
        'status': 'published',
        'description': 'Guided walk.',
      });
      repository.setPublishedListings([listing]);

      expect(repository.getById(listing.id), same(listing));
      expect(repository.getForDestination('nassau'), contains(listing));
      expect(repository.searchListings('nassau', 'harbor'), contains(listing));
      expect(repository.getForDestination('rome'), hasLength(6));
    });
  });
}
