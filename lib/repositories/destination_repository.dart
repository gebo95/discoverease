import 'package:flutter/foundation.dart';

import '../mock_data/destinations/mock_destination_areas.dart';
import '../mock_data/destinations/mock_destinations.dart';
import '../models/destination.dart';
import '../models/destination_area.dart';

class DestinationRepository extends ChangeNotifier {
  Destination _currentDestination = mockDestinations.first;

  Destination get currentDestination => _currentDestination;

  List<Destination> getAll() {
    return List.unmodifiable(mockDestinations);
  }

  Destination? getById(String id) {
    for (final destination in mockDestinations) {
      if (destination.id == id) {
        return destination;
      }
    }

    return null;
  }

  List<DestinationArea> getAreasForCurrentDestination() {
    return getAreasForDestination(_currentDestination.id);
  }

  List<DestinationArea> getAreasForDestination(String destinationId) {
    return mockDestinationAreas
        .where((area) => area.destinationId == destinationId)
        .toList();
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
