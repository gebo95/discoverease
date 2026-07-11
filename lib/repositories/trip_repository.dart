import '../mock_data/trips/mock_trips.dart';
import '../models/trip.dart';
import '../models/trip_day.dart';
import '../models/trip_experience.dart';
import '../models/trip_section.dart';
import 'package:flutter/foundation.dart';

class TripRepository extends ChangeNotifier {
  TripRepository();

  Trip _currentTrip = currentTrip;

  Trip getCurrentTrip() => _currentTrip;

  List<Trip> getUpcomingTrips() => [upcomingTrip];

  List<Trip> getMemories() => [memoryTrip1, memoryTrip2];

  bool isListingPlanned(String listingId) {
    return _currentTrip.days.any(
      (day) => day.experiences.any(
        (experience) => experience.listingId == listingId,
      ),
    );
  }

  void planExperience({
    required String listingId,
    required int dayIndex,
    required TripSection section,
  }) {
    final updatedDays = [..._currentTrip.days];

    final selectedDay = updatedDays[dayIndex];

    final newExperience = TripExperience(
      id: "${_currentTrip.id}-${selectedDay.title}-$listingId",
      listingId: listingId,
      section: section,
    );

    final updatedDay = TripDay(
      title: selectedDay.title,
      date: selectedDay.date,
      experiences: [...selectedDay.experiences, newExperience],
    );

    updatedDays[dayIndex] = updatedDay;

    _currentTrip = Trip(
      id: _currentTrip.id,
      title: _currentTrip.title,
      destination: _currentTrip.destination,
      startDate: _currentTrip.startDate,
      endDate: _currentTrip.endDate,
      days: updatedDays,
      estimatedBudget: _currentTrip.estimatedBudget,
    );
    notifyListeners();
  }
}
