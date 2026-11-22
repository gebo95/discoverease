import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../services/geocoding_service.dart';

/// Street address typed by hand, with an optional map pin. The pin can be set
/// by tapping the map, by "Find on map" (looks the typed address up) or by
/// "Use my location". Typing alone is always enough.
class AddressField extends StatefulWidget {
  const AddressField({
    super.key,
    required this.controller,
    required this.latitude,
    required this.longitude,
    required this.destinationName,
    required this.centerLatitude,
    required this.centerLongitude,
    required this.onPinChanged,
    this.validator,
    this.geocoder,
  });

  final TextEditingController controller;
  final double? latitude;
  final double? longitude;

  /// Added to address searches so "12 Bay St" finds the right city.
  final String destinationName;

  /// Where the map starts when there is no pin yet.
  final double? centerLatitude;
  final double? centerLongitude;
  final void Function(double? latitude, double? longitude) onPinChanged;
  final String? Function(String?)? validator;
  final GeocodingService? geocoder;

  @override
  State<AddressField> createState() => _AddressFieldState();
}

class _AddressFieldState extends State<AddressField> {
  final _map = MapController();
  late final GeocodingService _geocoder = widget.geocoder ?? GeocodingService();
  bool _busy = false;

  bool get _hasPin => widget.latitude != null && widget.longitude != null;

  void _say(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _setPin(double latitude, double longitude, {bool recenter = false}) {
    widget.onPinChanged(latitude, longitude);
    if (recenter) {
      try {
        _map.move(LatLng(latitude, longitude), 16);
      } catch (_) {
        // The map is not on screen yet; it starts at the pin next time.
      }
    }
  }

  Future<void> _run(Future<void> Function() task) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await task();
    } on StateError catch (error) {
      _say(error.message);
    } catch (_) {
      _say('Something went wrong. Type the address or tap the map instead.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _findAddress() => _run(() async {
    final text = widget.controller.text.trim();
    if (text.isEmpty) throw StateError('Type the street address first.');
    final place = await _geocoder.search(
      widget.destinationName.isEmpty ? text : '$text, ${widget.destinationName}',
    );
    if (place == null) {
      throw StateError('No match found. Tap the map to place the pin yourself.');
    }
    _setPin(place.latitude, place.longitude, recenter: true);
  });

  Future<void> _useMyLocation() => _run(() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw StateError('Location is turned off on this device.');
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw StateError(
        'Location permission was not granted. Type the address or tap the map instead.',
      );
    }
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      ),
    );
    _setPin(position.latitude, position.longitude, recenter: true);
    await _fillAddressIfEmpty(position.latitude, position.longitude);
  });

  Future<void> _fillAddressIfEmpty(double latitude, double longitude) async {
    if (widget.controller.text.trim().isNotEmpty) return;
    try {
      final street = await _geocoder.streetAddress(latitude, longitude);
      if (street != null && widget.controller.text.trim().isEmpty) {
        widget.controller.text = street;
      }
    } catch (_) {
      // The pin is set; the address can be typed.
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pin = _hasPin ? LatLng(widget.latitude!, widget.longitude!) : null;
    final center = pin ??
        (widget.centerLatitude != null && widget.centerLongitude != null
            ? LatLng(widget.centerLatitude!, widget.centerLongitude!)
            : const LatLng(25.0443, -77.3504));
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: widget.controller,
            decoration: const InputDecoration(labelText: 'Street address'),
            validator: widget.validator,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              OutlinedButton.icon(
                onPressed: _busy ? null : _findAddress,
                icon: const Icon(Icons.search),
                label: const Text('Find on map'),
              ),
              OutlinedButton.icon(
                onPressed: _busy ? null : _useMyLocation,
                icon: const Icon(Icons.my_location),
                label: const Text('Use my location'),
              ),
              if (pin != null)
                TextButton(
                  onPressed: _busy ? null : () => widget.onPinChanged(null, null),
                  child: const Text('Clear pin'),
                ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 220,
              child: FlutterMap(
                mapController: _map,
                options: MapOptions(
                  initialCenter: center,
                  initialZoom: pin == null ? 11 : 16,
                  onTap: (_, point) => _setPin(point.latitude, point.longitude),
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.discoverease.app',
                  ),
                  if (pin != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: pin,
                          width: 40,
                          height: 40,
                          alignment: Alignment.topCenter,
                          child: Icon(
                            Icons.location_on,
                            size: 40,
                            color: theme.colorScheme.error,
                          ),
                        ),
                      ],
                    ),
                  const RichAttributionWidget(
                    attributions: [TextSourceAttribution('© OpenStreetMap contributors')],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            pin == null
                ? 'Tap the map to drop a pin so travelers can get directions. The typed address works without one.'
                : 'Pin set. Travelers can tap the address for directions.',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
