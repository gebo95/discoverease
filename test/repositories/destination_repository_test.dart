import 'package:flutter_test/flutter_test.dart';
import 'package:discoverease/repositories/destination_repository.dart';

void main() {
  group('DestinationRepository', () {
    test('starts with the first curated destination', () {
      final repository = DestinationRepository();

      expect(repository.currentDestination.id, 'nassau');
      expect(repository.currentDestination.timezoneId, 'America/Nassau');
    });

    test(
      'searches destination, country, and region without case sensitivity',
      () {
        final repository = DestinationRepository();

        expect(repository.search('japan').single.id, 'tokyo');
        expect(repository.search('KANTO').single.name, 'Tokyo');
        expect(repository.search('rome').single.countryCode, 'IT');
        expect(repository.search('   '), repository.getAll());
      },
    );

    test('returns areas in the curated order for the requested destination', () {
      final repository = DestinationRepository();

      final tokyoAreas = repository.getAreasForDestination('tokyo');

      expect(tokyoAreas.map((area) => area.id), [
        'shibuya',
        'shinjuku',
        'asakusa',
        'tsukiji',
        'ueno',
        'akihabara',
      ]);
      expect(
        tokyoAreas.every((area) => area.destinationId == 'tokyo'),
        isTrue,
      );
    });

    test('ignores unknown destinations and only notifies for a real change', () {
      final repository = DestinationRepository();
      var notifications = 0;
      repository.addListener(() => notifications++);

      repository.selectDestination('missing');
      repository.selectDestination('nassau');
      expect(notifications, 0);

      repository.selectDestination('rome');
      expect(repository.currentDestination.id, 'rome');
      expect(notifications, 1);
    });
  });
}
