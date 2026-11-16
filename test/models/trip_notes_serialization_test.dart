import 'package:flutter_test/flutter_test.dart';
import 'package:discoverease/mock_data/trips/mock_trips.dart';
import 'package:discoverease/models/trip.dart';

void main() {
  test('trip notes survive account data serialization', () {
    final trip = Trip(
      id: currentTrip.id,
      title: currentTrip.title,
      destination: currentTrip.destination,
      destinationId: currentTrip.destinationId,
      days: currentTrip.days,
      estimatedBudget: currentTrip.estimatedBudget,
      notes: 'Bring printed tickets.',
    );

    final restored = Trip.fromJson(trip.toJson());

    expect(restored.notes, 'Bring printed tickets.');
    expect(restored.estimatedBudget, currentTrip.estimatedBudget);
  });
}
