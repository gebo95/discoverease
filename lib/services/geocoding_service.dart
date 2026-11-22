import 'dart:convert';

import 'package:http/http.dart' as http;

/// A place found on the map.
class GeoPlace {
  const GeoPlace({required this.latitude, required this.longitude, this.label = ''});
  final double latitude;
  final double longitude;
  final String label;
}

/// Looks addresses up (and the other way round) with OpenStreetMap's free
/// Nominatim service. It is only called when an owner taps a button, never
/// while typing, which keeps usage inside Nominatim's fair-use limits.
class GeocodingService {
  GeocodingService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const _host = 'nominatim.openstreetmap.org';
  static const _failure =
      'Could not reach the map service. Try again, or tap the map to place the pin.';

  /// The best match for [query], or null when nothing is found.
  Future<GeoPlace?> search(String query) async {
    final text = query.trim();
    if (text.isEmpty) return null;
    final body = await _get('/search', {'format': 'jsonv2', 'limit': '1', 'q': text});
    return body is List && body.isNotEmpty ? parsePlace(body.first) : null;
  }

  /// A short street address for a point, or null when none is known.
  Future<String?> streetAddress(double latitude, double longitude) async {
    final body = await _get('/reverse', {
      'format': 'jsonv2',
      'addressdetails': '1',
      'lat': '$latitude',
      'lon': '$longitude',
    });
    return body is Map ? streetFrom(body) : null;
  }

  Future<Object?> _get(String path, Map<String, String> query) async {
    try {
      final response = await _client.get(
        Uri.https(_host, path, query),
        headers: const {'Accept-Language': 'en'},
      );
      if (response.statusCode != 200) throw StateError(_failure);
      return jsonDecode(response.body);
    } on StateError {
      rethrow;
    } catch (_) {
      throw StateError(_failure);
    }
  }

  /// Reads one Nominatim search result. Coordinates arrive as text.
  static GeoPlace? parsePlace(Object? raw) {
    if (raw is! Map) return null;
    final latitude = double.tryParse('${raw['lat']}');
    final longitude = double.tryParse('${raw['lon']}');
    if (latitude == null || longitude == null) return null;
    if (latitude < -90 || latitude > 90 || longitude < -180 || longitude > 180) {
      return null;
    }
    return GeoPlace(
      latitude: latitude,
      longitude: longitude,
      label: raw['display_name'] is String ? raw['display_name'] as String : '',
    );
  }

  /// "123 Bay Street" from a reverse lookup, falling back to the first part
  /// of the full name.
  static String? streetFrom(Map<dynamic, dynamic> result) {
    final address = result['address'];
    if (address is Map) {
      final number = '${address['house_number'] ?? ''}'.trim();
      final road = '${address['road'] ?? ''}'.trim();
      if (road.isNotEmpty) return number.isEmpty ? road : '$number $road';
    }
    final name = result['display_name'];
    if (name is String && name.trim().isNotEmpty) {
      return name.split(',').first.trim();
    }
    return null;
  }
}
