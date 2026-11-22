import 'package:discoverease/shared/utils/directions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a pin gives exact directions', () {
    final uri = directionsUri(latitude: 25.078, longitude: -77.343, address: 'ignored');
    expect(uri!.host, 'www.google.com');
    expect(uri.path, '/maps/dir/');
    expect(uri.queryParameters['destination'], '25.078,-77.343');
  });

  test('without a pin the address is searched with the destination', () {
    final uri = directionsUri(address: ' 12 Bay St ', destination: 'Nassau');
    expect(uri!.path, '/maps/search/');
    expect(uri.queryParameters['query'], '12 Bay St, Nassau');
    expect(directionsUri(address: '12 Bay St')!.queryParameters['query'], '12 Bay St');
  });

  test('nothing to look up gives no link', () {
    expect(directionsUri(), isNull);
    expect(directionsUri(address: '   ', destination: 'Nassau'), isNull);
    expect(directionsUri(latitude: 95, longitude: 0), isNull);
    expect(directionsUri(latitude: 25), isNull);
  });
}
