import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:discoverease/models/saved_experience.dart';
import 'package:discoverease/models/trip.dart';
import 'package:discoverease/models/trip_day.dart';
import 'package:discoverease/models/trip_experience.dart';
import 'package:discoverease/models/trip_reservation.dart';
import 'package:discoverease/models/trip_section.dart';

void main() {
  group('backend document serialization', () {
    test('round trips trip dates and nested itinerary data', () {
      final original = Trip(
        id: 'rome-weekend',
        title: 'Rome weekend',
        destination: 'Italy',
        destinationId: 'rome',
        startDate: DateTime(2027, 5, 1),
        endDate: DateTime(2027, 5, 2),
        estimatedBudget: 1500.5,
        days: [
          TripDay(
            title: 'Day 1',
            date: DateTime(2027, 5, 1),
            experiences: [
              TripExperience(
                id: 'visit-colosseum',
                listingId: 'colosseum',
                section: TripSection.morning,
                time: const TimeOfDay(hour: 9, minute: 15),
                closingTime: const TimeOfDay(hour: 17, minute: 30),
                estimatedCost: 42.5,
                travelerCountOverride: 2,
                notes: 'Bring tickets',
                completed: true,
                travelMinutes: 25,
                arrivalBufferMinutes: 15,
                reservation: TripReservation(
                  type: TripReservationType.attraction,
                  confirmationNumber: 'ROM-123',
                  reminderTime: DateTime.utc(2027, 5, 1, 8),
                ),
              ),
            ],
          ),
        ],
      );

      final json = original.toJson();
      final restored = Trip.fromJson(json);

      expect(json['schemaVersion'], Trip.schemaVersion);
      expect(json['startDate'], '2027-05-01');
      expect(restored.id, original.id);
      expect(restored.destinationId, 'rome');
      expect(restored.startDate, DateTime(2027, 5, 1));
      expect(restored.endDate, DateTime(2027, 5, 2));
      expect(restored.estimatedBudget, 1500.5);
      expect(restored.totalEstimatedCost, 42.5);
      expect(restored.days.single.date, DateTime(2027, 5, 1));

      final experience = restored.days.single.experiences.single;
      expect(experience.section, TripSection.morning);
      expect(experience.time, const TimeOfDay(hour: 9, minute: 15));
      expect(experience.closingTime, const TimeOfDay(hour: 17, minute: 30));
      expect(experience.completed, isTrue);
      expect(experience.reservation?.confirmationNumber, 'ROM-123');
      expect(experience.reservation?.reminderTime, DateTime.utc(2027, 5, 1, 8));
    });

    test('round trips saved experience records', () {
      const saved = SavedExperience(
        id: 'saved-colosseum',
        listingId: 'colosseum',
        destination: 'Rome',
        listName: 'History',
      );

      expect(SavedExperience.fromJson(saved.toJson()).listName, 'History');
      expect(SavedExperience.fromJson(saved.toJson()).listingId, 'colosseum');
    });

    test('rejects unsupported schema versions and unknown enums', () {
      expect(
        () => Trip.fromJson({
          'schemaVersion': 99,
          'id': 'trip',
          'title': 'Trip',
          'destination': 'Rome',
        }),
        throwsFormatException,
      );
      expect(
        () => TripExperience.fromJson({
          'id': 'experience',
          'listingId': 'place',
          'section': 'midnight',
        }),
        throwsFormatException,
      );
    });
  });
}
