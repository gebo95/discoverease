import 'package:discoverease/models/listing.dart';
import 'package:discoverease/repositories/listing_repository.dart';
import 'package:flutter_test/flutter_test.dart';

Listing _listing(String id, {String category = 'Tours', String subcategory = '', List<String> features = const [], List<String> perfectFor = const []}) =>
    Listing.fromCatalogJson({
      'id': id,
      'title': id,
      'category': category,
      'subcategory': subcategory,
      'destinationId': 'nassau',
      'destination': 'Bahamas',
      'features': features,
      'perfectFor': perfectFor,
      'status': 'published',
    });

void main() {
  final repository = ListingRepository()
    ..setPublishedListings([
      _listing('zz-tour', category: 'Tours', subcategory: 'Boat Tour'),
      _listing('zz-bar', category: 'Dining', subcategory: 'Bar & Lounge, Beach, Party'),
      _listing('zz-spa', category: 'Activities', subcategory: 'Spa & Wellness'),
      _listing('zz-sunset', category: 'Tours', perfectFor: ['Sunset Lovers']),
    ]);

  test('a category finds listings by category, any of their types, or their tags', () {
    expect(ListingRepository.matchesCategory(_listing('a', category: 'Tours'), 'tour'), isTrue);
    expect(ListingRepository.matchesCategory(_listing('a', subcategory: 'Bar, Beach'), 'Beach'), isTrue);
    expect(ListingRepository.matchesCategory(_listing('a', features: ['Ocean View']), 'ocean'), isTrue);
    expect(ListingRepository.matchesCategory(_listing('a', category: 'Dining'), 'Tours'), isFalse);
    expect(ListingRepository.matchesCategory(_listing('a'), '  '), isTrue);
  });

  test('a bar tagged Beach shows up under Beach as well as Dining', () {
    List<String> ids(String category) => repository
        .searchListings('nassau', '', category: category)
        .map((l) => l.id)
        .where((id) => id.startsWith('zz-'))
        .toList();
    expect(ids('Dining'), ['zz-bar']);
    expect(ids('Beach'), ['zz-bar']);
    expect(ids('Tour'), containsAll(['zz-tour', 'zz-sunset']));
    expect(ids('Tour'), isNot(contains('zz-bar')));
  });

  test('"See all" gives the same places the home row shows', () {
    for (final category in ['Tour', 'Beach', 'Bar']) {
      final row = repository.getByCategory('nassau', category).map((l) => l.id).toSet();
      final explore = repository
          .searchListings('nassau', '', category: category)
          .map((l) => l.id)
          .toSet();
      expect(explore, row, reason: category);
    }
  });

  test('category combines with search and a mood', () {
    final results = repository.searchListings('nassau', 'boat', category: 'Tour');
    expect(results.map((l) => l.id), contains('zz-tour'));
    expect(results.map((l) => l.id), isNot(contains('zz-sunset')));
    final sunset = repository.searchListings('nassau', '', filter: '🌅 Sunset');
    expect(sunset.map((l) => l.id), contains('zz-sunset'));
  });

  test('no category means everything', () {
    expect(
      repository.searchListings('nassau', '', category: null).length,
      repository.searchListings('nassau', '').length,
    );
  });
}
