import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:discoverease/models/trip_reservation.dart';
import 'package:discoverease/models/trip_section.dart';
import 'package:discoverease/repositories/trip_repository.dart';

void main() {
  group('TripRepository Companion inputs', () {
    test('account hydration excludes guest trips and creates a clean first trip', () {
      final repository = TripRepository();

      repository.loadAccountData(current: null, upcoming: const []);

      expect(repository.hasCurrentTrip, isFalse);
      expect(repository.usingDemoData, isFalse);
      expect(repository.getUpcomingTrips(), isEmpty);
      expect(repository.getMemories(), isEmpty);

      final created = repository.createTrip(
        destinationId: 'rome',
        destination: 'Italy',
      );
      expect(repository.hasCurrentTrip, isTrue);
      expect(repository.getUpcomingTrips(), isEmpty);
      expect(repository.getCurrentTrip(), created);
      repository.dispose();
    });

    test('signing out restores local demo trips', () {
      final repository = TripRepository();
      repository.loadAccountData(current: null, upcoming: const []);

      repository.loadDemoData();

      expect(repository.usingDemoData, isTrue);
      expect(repository.hasCurrentTrip, isTrue);
      expect(repository.getCurrentTrip().id, 'bahamas-adventure');
      expect(repository.getUpcomingTrips().single.id, 'tokyo-2027');
      repository.dispose();
    });

    test('creates a destination based trip with one day per date', () {
      final repository = TripRepository();
      final created = repository.createTrip(
        destinationId: 'tokyo',
        destination: 'Japan',
        title: 'Tokyo weekend',
        startDate: DateTime(2026, 10, 2),
        endDate: DateTime(2026, 10, 4),
      );

      expect(repository.getCurrentTrip().id, created.id);
      expect(created.destinationId, 'tokyo');
      expect(created.days.map((day) => day.title), ['Day 1', 'Day 2', 'Day 3']);
      expect(created.days.last.date, DateTime(2026, 10, 4));
      expect(repository.getUpcomingTrips().any((trip) => trip.id == 'bahamas-adventure'), isTrue);
      repository.dispose();
    });

    test('editing trip details preserves planned experiences when dates shrink', () {
      final repository = TripRepository();
      repository.updateCurrentTrip(
        title: 'Bahamas Adventure',
        destinationId: 'nassau',
        destination: 'Bahamas',
        startDate: DateTime(2026, 10, 1),
        endDate: DateTime(2026, 10, 3),
      );
      repository.planExperience(
        listingId: 'extra-place',
        dayIndex: 2,
        section: TripSection.afternoon,
      );
      final plannedCount = repository.getCurrentTrip().plannedExperiences;

      final edited = repository.updateCurrentTrip(
        title: 'Updated trip',
        destinationId: 'rome',
        destination: 'Italy',
        startDate: DateTime(2027, 5, 1),
        endDate: DateTime(2027, 5, 1),
      );

      expect(edited.title, 'Updated trip');
      expect(edited.destinationId, 'rome');
      expect(edited.days, hasLength(1));
      expect(edited.plannedExperiences, plannedCount);
      expect(edited.days.single.experiences.last.listingId, 'extra-place');
      repository.dispose();
    });

    test('activating an upcoming trip makes it editable and gives it a day', () {
      final repository = TripRepository();

      expect(repository.activateTrip('tokyo-2027'), isTrue);
      expect(repository.getCurrentTrip().destination, 'Japan');
      expect(repository.getCurrentTrip().days, hasLength(1));
      expect(repository.getCurrentTrip().days.single.title, 'Day 1');
      expect(repository.activateTrip('missing'), isFalse);
      repository.dispose();
    });

    test('removing a planned experience removes its listing from the day', () {
      final repository = TripRepository();
      repository.planExperience(
        listingId: 'remove-me',
        dayIndex: 0,
        section: TripSection.evening,
      );
      final planned = repository.getCurrentTrip().days.first.experiences.last;

      expect(repository.removeExperience(planned.id), isTrue);
      expect(repository.isListingPlanned('remove-me'), isFalse);
      expect(repository.removeExperience(planned.id), isFalse);
      repository.dispose();
    });

    test('saves schedule, travel estimate, and reservation details', () {
      final repository = TripRepository();
      final reservation = TripReservation(
        type: TripReservationType.other,
        confirmationNumber: 'ABC-123',
      );

      repository.planExperience(
        listingId: 'fish-fry',
        dayIndex: 0,
        section: TripSection.evening,
        time: const TimeOfDay(hour: 18, minute: 30),
        closingTime: const TimeOfDay(hour: 21, minute: 0),
        travelMinutes: 20,
        reservation: reservation,
      );

      final saved = repository.getCurrentTrip().days.first.experiences.last;
      expect(saved.time, const TimeOfDay(hour: 18, minute: 30));
      expect(saved.closingTime, const TimeOfDay(hour: 21, minute: 0));
      expect(saved.travelMinutes, 20);
      expect(saved.reservation?.confirmationNumber, 'ABC-123');
      repository.dispose();
    });

    test('completion changes notify the dashboard and update the trip', () {
      final repository = TripRepository();
      var notifications = 0;
      repository.addListener(() => notifications++);

      repository.setExperienceCompleted(
        experienceId: 'trip-exp-1',
        completed: true,
      );

      expect(repository.getCurrentTrip().days.first.experiences.first.completed, isTrue);
      expect(notifications, 1);
      repository.dispose();
    });

    test('trip notes update, notify, and survive itinerary edits', () {
      final repository = TripRepository();
      var notifications = 0;
      repository.addListener(() => notifications++);

      repository.updateNotes('  Pack sunscreen and print tickets.  ');
      expect(repository.getCurrentTrip().notes, 'Pack sunscreen and print tickets.');

      repository.planExperience(
        listingId: 'kept-after-budget-edit',
        dayIndex: 0,
        section: TripSection.morning,
      );
      expect(repository.getCurrentTrip().notes, 'Pack sunscreen and print tickets.');

      repository.updateNotes('   ');
      expect(repository.getCurrentTrip().notes, isNull);
      expect(notifications, 3);
      repository.dispose();
    });

    test('trip total adds per-experience estimates and updates when edited', () {
      final repository = TripRepository();
      repository.planExperience(
        listingId: 'paid-tour',
        dayIndex: 0,
        section: TripSection.morning,
        estimatedCost: 42.50,
        notes: 'Bring the printed voucher.',
      );
      repository.planExperience(
        listingId: 'paid-meal',
        dayIndex: 0,
        section: TripSection.evening,
        estimatedCost: 27,
      );

      final first = repository.getCurrentTrip().days.first.experiences.singleWhere(
        (experience) => experience.listingId == 'paid-tour',
      );
      expect(repository.getCurrentTrip().totalEstimatedCost, 69.50);
      expect(first.notes, 'Bring the printed voucher.');

      repository.updateExperienceDetails(
        experienceId: first.id,
        estimatedCost: 50,
        notes: 'Arrive 15 minutes early.',
      );
      expect(repository.getCurrentTrip().totalEstimatedCost, 77);
      expect(
        repository.getCurrentTrip().days.first.experiences.singleWhere(
          (experience) => experience.listingId == 'paid-tour',
        ).notes,
        'Arrive 15 minutes early.',
      );

      repository.updateExperienceDetails(
        experienceId: first.id,
        estimatedCost: null,
        notes: null,
      );
      expect(repository.getCurrentTrip().totalEstimatedCost, 27);
      expect(
        repository.getCurrentTrip().days.first.experiences.singleWhere(
          (experience) => experience.listingId == 'paid-tour',
        ).notes,
        isNull,
      );
      repository.dispose();
    });

    test('each day budget is separate while trip total includes every day', () {
      final repository = TripRepository();
      repository.createTrip(
        destinationId: 'nassau',
        destination: 'Bahamas',
        startDate: DateTime(2027, 5, 1),
        endDate: DateTime(2027, 5, 2),
      );
      repository.planExperience(
        listingId: 'day-one',
        dayIndex: 0,
        section: TripSection.morning,
        estimatedCost: 40,
      );
      repository.planExperience(
        listingId: 'day-two',
        dayIndex: 1,
        section: TripSection.evening,
        estimatedCost: 25,
      );

      final trip = repository.getCurrentTrip();
      expect(trip.days[0].totalEstimatedCost, 40);
      expect(trip.days[1].totalEstimatedCost, 25);
      expect(trip.totalEstimatedCost, 65);
      repository.dispose();
    });
  });
}
