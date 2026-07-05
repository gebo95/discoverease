import '../mock_data/trips/mock_trips.dart';
import '../models/trip.dart';

class TripRepository {
  const TripRepository();

  Trip getCurrentTrip() => currentTrip;

  List<Trip> getUpcomingTrips() => [upcomingTrip];

  List<Trip> getMemories() => [memoryTrip1, memoryTrip2];
}
