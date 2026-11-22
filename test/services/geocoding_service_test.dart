import 'package:discoverease/services/geocoding_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('reading a search result', () {
    test('turns text coordinates into numbers', () {
      final place = GeocodingService.parsePlace({
        'lat': '25.0780',
        'lon': '-77.3430',
        'display_name': 'Bay Street, Nassau',
      });
      expect(place!.latitude, 25.078);
      expect(place.longitude, -77.343);
      expect(place.label, 'Bay Street, Nassau');
    });

    test('rejects missing, broken or out of range coordinates', () {
      expect(GeocodingService.parsePlace(null), isNull);
      expect(GeocodingService.parsePlace({'lat': 'x', 'lon': '1'}), isNull);
      expect(GeocodingService.parsePlace({'lat': '95', 'lon': '1'}), isNull);
      expect(GeocodingService.parsePlace({'lat': '1', 'lon': '181'}), isNull);
    });
  });

  group('short street address', () {
    test('uses house number and road when known', () {
      expect(
        GeocodingService.streetFrom({
          'address': {'house_number': '12', 'road': 'Bay Street'},
          'display_name': 'ignored',
        }),
        '12 Bay Street',
      );
      expect(GeocodingService.streetFrom({'address': {'road': 'Bay Street'}}), 'Bay Street');
    });

    test('falls back to the first part of the full name', () {
      expect(
        GeocodingService.streetFrom({'display_name': 'Arawak Cay, Nassau, Bahamas'}),
        'Arawak Cay',
      );
      expect(GeocodingService.streetFrom({}), isNull);
    });
  });

  group('lookups', () {
    test('search sends the query and returns the first match', () async {
      late Uri seen;
      final service = GeocodingService(
        client: MockClient((request) async {
          seen = request.url;
          return http.Response('[{"lat":"25.07","lon":"-77.34","display_name":"X"}]', 200);
        }),
      );
      final place = await service.search('12 Bay St, Nassau');
      expect(seen.host, 'nominatim.openstreetmap.org');
      expect(seen.path, '/search');
      expect(seen.queryParameters['q'], '12 Bay St, Nassau');
      expect(place!.latitude, 25.07);
    });

    test('search finds nothing for blank text or an empty result', () async {
      var calls = 0;
      final service = GeocodingService(
        client: MockClient((_) async {
          calls++;
          return http.Response('[]', 200);
        }),
      );
      expect(await service.search('   '), isNull);
      expect(calls, 0);
      expect(await service.search('nowhere'), isNull);
    });

    test('a failed request becomes a plain message', () async {
      final service = GeocodingService(
        client: MockClient((_) async => http.Response('busy', 429)),
      );
      expect(service.search('x'), throwsA(isA<StateError>()));
      final broken = GeocodingService(
        client: MockClient((_) async => throw http.ClientException('offline')),
      );
      expect(broken.streetAddress(1, 2), throwsA(isA<StateError>()));
    });
  });
}
