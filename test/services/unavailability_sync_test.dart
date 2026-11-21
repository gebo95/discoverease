import 'package:discoverease/models/trip.dart';
import 'package:discoverease/models/trip_day.dart';
import 'package:discoverease/models/trip_experience.dart';
import 'package:discoverease/models/trip_section.dart';
import 'package:discoverease/services/firebase_unavailability_sync_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('collects saved ids and every trip stop, once each', () {
    final trip = Trip(
      id: 't1',
      title: 'Nassau',
      destination: 'Bahamas',
      days: [
        TripDay(
          title: 'Day 1',
          experiences: [
            TripExperience(id: 'e1', listingId: 'cruise', section: TripSection.morning),
            TripExperience(id: 'e2', listingId: 'kayak', section: TripSection.morning),
          ],
        ),
      ],
    );
    final ids = FirebaseUnavailabilitySyncService.collectListingIds(
      savedIds: ['cruise', 'beach'],
      trips: [trip],
    );
    expect(ids, {'cruise', 'kayak', 'beach'});
  });

  test('ignores empty ids and ids that cannot be document names', () {
    final ids = FirebaseUnavailabilitySyncService.collectListingIds(
      savedIds: ['', 'a/b', 'ok'],
      trips: const [],
    );
    expect(ids, {'ok'});
  });

  test('splits ids into groups of at most 30', () {
    final ids = List.generate(65, (i) => 'id-${i.toString().padLeft(3, '0')}');
    final groups = FirebaseUnavailabilitySyncService.chunk(ids);
    expect(groups.map((g) => g.length), [30, 30, 5]);
    expect(groups.expand((g) => g).toSet(), ids.toSet());
    expect(FirebaseUnavailabilitySyncService.chunk(const []), isEmpty);
  });
}
