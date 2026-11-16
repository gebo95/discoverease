import 'package:flutter/foundation.dart';

import '../mock_data/destinations/mock_destination_areas.dart';
import '../mock_data/destinations/mock_destinations.dart';
import '../models/destination.dart';
import '../models/destination_area.dart';

class DestinationRepository extends ChangeNotifier {
  final List<Destination> _destinations;
  final List<DestinationArea> _areas;
  late Destination _currentDestination;

  DestinationRepository({
    List<Destination> destinations = mockDestinations,
    List<DestinationArea> areas = mockDestinationAreas,
  }) : _destinations = List.unmodifiable(destinations),
       _areas = List.unmodifiable(areas) {
    if (_destinations.isEmpty) {
      throw ArgumentError.value(destinations, 'destinations', 'Cannot be empty');
    }
    _currentDestination = _destinations.first;
  }

  Destination get currentDestination => _currentDestination;

  List<Destination> getAll() {
    return _destinations;
  }

  Destination? getById(String id) {
    for (final destination in _destinations) {
      if (destination.id == id) {
        return destination;
      }
    }
    return null;
  }

  List<Destination> search(String query) {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) {
      return _destinations;
    }
    return _destinations.where((destination) {
      return destination.name.toLowerCase().contains(normalizedQuery) ||
          destination.country.toLowerCase().contains(normalizedQuery) ||
          destination.region.toLowerCase().contains(normalizedQuery) ||
          destination.countryCode.toLowerCase() == normalizedQuery;
    }).toList(growable: false);
  }

  List<DestinationArea> getAreasForCurrentDestination() {
    return getAreasForDestination(_currentDestination.id);
  }

  List<DestinationArea> getAreasForDestination(String destinationId) {
    final destination = getById(destinationId);
    if (destination == null) {
      return const [];
    }
    final areaById = {for (final area in _areas) area.id: area};
    return destination.areaIds
        .map((id) => areaById[id])
        .whereType<DestinationArea>()
        .toList(growable: false);
  }

  DestinationArea? getAreaById(String areaId) {
    for (final area in _areas) {
      if (area.id == areaId) {
        return area;
      }
    }
    return null;
  }

  List<DestinationArea> searchAreas(String destinationId, String query) {
    final areas = getAreasForDestination(destinationId);
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) {
      return areas;
    }
    return areas.where((area) {
      return area.name.toLowerCase().contains(normalizedQuery) ||
          (area.subtitle?.toLowerCase().contains(normalizedQuery) ?? false);
    }).toList(growable: false);
  }

  void selectDestination(String destinationId) {
    final destination = getById(destinationId);

    if (destination == null || destination.id == _currentDestination.id) {
      return;
    }

    _currentDestination = destination;
    notifyListeners();
  }
}
