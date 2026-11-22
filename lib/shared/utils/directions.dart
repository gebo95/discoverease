/// The web address that opens directions to a place in the device's maps app.
/// Uses the exact pin when there is one, otherwise the typed address with the
/// destination added so the search lands in the right city. Null when there is
/// nothing to look up.
Uri? directionsUri({
  double? latitude,
  double? longitude,
  String address = '',
  String destination = '',
}) {
  if (latitude != null &&
      longitude != null &&
      latitude.abs() <= 90 &&
      longitude.abs() <= 180) {
    return Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'destination': '$latitude,$longitude',
    });
  }
  final text = address.trim();
  if (text.isEmpty) return null;
  final query = destination.trim().isEmpty ? text : '$text, ${destination.trim()}';
  return Uri.https('www.google.com', '/maps/search/', {'api': '1', 'query': query});
}
