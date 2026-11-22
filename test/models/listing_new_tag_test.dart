import 'package:discoverease/models/listing.dart';
import 'package:flutter_test/flutter_test.dart';

Listing _listing({Object? publishedAt, String displayStatus = 'New', Object? endsAt}) =>
    Listing.fromCatalogJson({
      'id': 'zz-new-test',
      'title': 'Sunset Cruise',
      'category': 'Tours',
      'destinationId': 'nassau',
      'destination': 'Bahamas',
      'status': 'published',
      'displayStatus': displayStatus,
      'publishedAt': publishedAt,
      'endsAt': endsAt,
    });

void main() {
  test('a freshly approved listing shows the New tag', () {
    final listing = _listing(publishedAt: DateTime.now().subtract(const Duration(days: 3)));
    expect(listing.status, 'New');
  });

  test('the New tag wears off after two weeks and leaves no tag', () {
    final old = _listing(publishedAt: DateTime.now().subtract(newListingWindow + const Duration(days: 1)));
    expect(old.status, '');
  });

  test('a listing with no publish date keeps its tag', () {
    expect(_listing().status, 'New');
  });

  test('other tags never wear off', () {
    final old = DateTime.now().subtract(const Duration(days: 90));
    expect(_listing(publishedAt: old, displayStatus: 'Popular').status, 'Popular');
  });

  test('an end date still shows on an old listing', () {
    final old = DateTime.now().subtract(const Duration(days: 90));
    final listing = _listing(publishedAt: old, endsAt: DateTime.now().add(const Duration(days: 10)));
    expect(listing.status, startsWith('Ends '));
  });

  test('an owner highlight takes the place of New, but an end date still comes first', () {
    Listing withHighlight({Object? endsAt}) => Listing.fromCatalogJson({
      'id': 'zz-hl',
      'title': 'T',
      'category': 'Tours',
      'destinationId': 'nassau',
      'destination': 'Bahamas',
      'status': 'published',
      'displayStatus': 'New',
      'highlight': 'Local Favorite',
      'endsAt': endsAt,
    });
    expect(withHighlight().status, 'Local Favorite');
    expect(
      withHighlight(endsAt: DateTime.now().add(const Duration(days: 5))).status,
      startsWith('Ends '),
    );
  });

  test('a highlight is kept after the New tag would have worn off', () {
    final listing = Listing.fromCatalogJson({
      'id': 'zz-hl2',
      'title': 'T',
      'category': 'Tours',
      'destinationId': 'nassau',
      'destination': 'Bahamas',
      'status': 'published',
      'displayStatus': 'New',
      'highlight': 'Hidden Gem',
      'publishedAt': DateTime.now().subtract(const Duration(days: 200)),
    });
    expect(listing.status, 'Hidden Gem');
  });
}
