import 'package:discoverease/models/listing.dart';
import 'package:flutter_test/flutter_test.dart';

Listing _listing({Object? endsAt, String displayStatus = 'New'}) =>
    Listing.fromCatalogJson({
      'id': 'zz-end-test',
      'title': 'Sunset Cruise',
      'category': 'Tours',
      'destinationId': 'nassau',
      'destination': 'Bahamas',
      'status': 'published',
      'displayStatus': displayStatus,
      'endsAt': endsAt,
    });

void main() {
  final future = DateTime.now().add(const Duration(days: 20));

  group('end date on a listing', () {
    test('shows "Ends <date>" in place of the usual status badge', () {
      final listing = _listing(endsAt: future);
      expect(listing.endsAt, future);
      expect(listing.status, 'Ends ${Listing.shortDate(future)}');
    });

    test('keeps the normal status when there is no end date', () {
      final listing = _listing();
      expect(listing.endsAt, isNull);
      expect(listing.status, 'New');
    });

    test('keeps the normal status once the date has passed', () {
      final listing = _listing(endsAt: DateTime.now().subtract(const Duration(days: 1)));
      expect(listing.status, 'New');
    });
  });

  group('trip warning', () {
    final endsAt = DateTime(2026, 12, 10, 23, 59, 59);

    test('is null when there is no end date', () {
      expect(_listing().endWarning(dayDate: DateTime(2027, 1, 1)), isNull);
      expect(_listing().endWarning(), isNull);
    });

    test('warns firmly when the trip day is after the end date', () {
      final warning = _listing(endsAt: endsAt).endWarning(dayDate: DateTime(2026, 12, 11));
      expect(warning, isNotNull);
      expect(warning, contains('before this day of your trip'));
    });

    test('stays quiet on the end date itself and before it', () {
      final listing = _listing(endsAt: endsAt);
      expect(listing.endWarning(dayDate: DateTime(2026, 12, 10)), isNull);
      expect(listing.endWarning(dayDate: DateTime(2026, 12, 1)), isNull);
    });

    test('reminds the traveler to check when the trip has no dates yet', () {
      final warning = _listing(endsAt: endsAt).endWarning();
      expect(warning, isNotNull);
      expect(warning, contains('Check that it is still running'));
    });
  });
}
