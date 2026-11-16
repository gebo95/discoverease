import 'package:flutter_test/flutter_test.dart';
import 'package:discoverease/repositories/listing_repository.dart';

void main() {
  group('ListingRepository destination filters', () {
    final repository = ListingRepository();

    test('uses stable destination IDs and keeps country-name compatibility', () {
      final byId = repository.getForDestination('nassau');
      final byCountry = repository.getForDestination('Bahamas');

      expect(byId, isNotEmpty);
      expect(
        byCountry.map((listing) => listing.id),
        orderedEquals(byId.map((listing) => listing.id)),
      );
      expect(
        byId.every((listing) => listing.destinationId == 'nassau'),
        isTrue,
      );
      expect(repository.getForDestination('rome').length, 6);
    });

    test('filters area and text search together', () {
      final results = repository.searchListings(
        'nassau',
        'market',
        areaId: 'downtown-nassau',
      );

      expect(results.map((listing) => listing.id), ['straw-market']);
    });

    test('does not leak another destination into an area result', () {
      final results = repository.getForArea('rome', 'downtown-nassau');

      expect(results, isEmpty);
    });
  });
}
