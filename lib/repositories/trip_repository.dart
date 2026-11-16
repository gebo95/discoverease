import 'package:flutter/material.dart';

import '../mock_data/trips/mock_trips.dart';
import '../models/trip.dart';
import '../models/trip_day.dart';
import '../models/trip_experience.dart';
import '../models/trip_section.dart';
import '../models/trip_reservation.dart';

class TripRepository extends ChangeNotifier {
  TripRepository();

  Trip _currentTrip = currentTrip;
  final List<Trip> _upcomingTrips = [upcomingTrip];
  List<Trip> _memories = [memoryTrip1, memoryTrip2];
  bool _hasCurrentTrip = true;
  bool _usingDemoData = true;

  Trip getCurrentTrip() => _currentTrip;
  bool get hasCurrentTrip => _hasCurrentTrip;
  bool get usingDemoData => _usingDemoData;

  List<Trip> getUpcomingTrips() => List.unmodifiable(_upcomingTrips);

  List<Trip> getMemories() => List.unmodifiable(_memories);

  /// Replaces guest demo trips with the signed-in user's Firestore data.
  /// An empty account has no active trip; the placeholder is never persisted.
  void loadAccountData({required Trip? current, required List<Trip> upcoming}) {
    _usingDemoData = false;
    _hasCurrentTrip = current != null;
    _currentTrip = current ?? const Trip(
      id: 'account-no-current-trip',
      title: 'Plan your next adventure',
      destination: 'Choose a destination',
    );
    _upcomingTrips
      ..clear()
      ..addAll(upcoming);
    _memories = [];
    notifyListeners();
  }

  /// Restores the existing local demo experience after the account signs out.
  void loadDemoData() {
    _usingDemoData = true;
    _hasCurrentTrip = true;
    _currentTrip = currentTrip;
    _upcomingTrips
      ..clear()
      ..add(upcomingTrip);
    _memories = [memoryTrip1, memoryTrip2];
    notifyListeners();
  }

  Trip createTrip({
    required String destinationId,
    required String destination,
    String? title,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    _validateDateRange(startDate, endDate);
    final newTrip = Trip(
      id: 'trip-$destinationId-${DateTime.now().microsecondsSinceEpoch}',
      title: title?.trim().isNotEmpty == true
          ? title!.trim()
          : '$destination trip',
      destination: destination,
      destinationId: destinationId,
      startDate: _dateOnly(startDate),
      endDate: _dateOnly(endDate),
      days: _buildDays(startDate: startDate, endDate: endDate),
    );

    if (_hasCurrentTrip) {
      _upcomingTrips.removeWhere((trip) => trip.id == _currentTrip.id);
      _upcomingTrips.add(_currentTrip);
    }
    _currentTrip = newTrip;
    _hasCurrentTrip = true;
    notifyListeners();
    return newTrip;
  }

  Trip updateCurrentTrip({
    required String title,
    required String destinationId,
    required String destination,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    _validateDateRange(startDate, endDate);
    _currentTrip = Trip(
      id: _currentTrip.id,
      title: title.trim().isEmpty ? '$destination trip' : title.trim(),
      destination: destination,
      destinationId: destinationId,
      startDate: _dateOnly(startDate),
      endDate: _dateOnly(endDate),
      days: _buildDays(
        startDate: startDate,
        endDate: endDate,
        existingDays: _currentTrip.days,
      ),
      estimatedBudget: _currentTrip.estimatedBudget,
      notes: _currentTrip.notes,
    );
    _hasCurrentTrip = true;
    notifyListeners();
    return _currentTrip;
  }

  bool activateTrip(String tripId) {
    final index = _upcomingTrips.indexWhere((trip) => trip.id == tripId);
    if (index < 0) return false;

    final selectedTrip = _upcomingTrips.removeAt(index);
    final selected = selectedTrip.days.isEmpty
        ? Trip(
            id: selectedTrip.id,
            title: selectedTrip.title,
            destination: selectedTrip.destination,
            destinationId: selectedTrip.destinationId,
            startDate: selectedTrip.startDate,
            endDate: selectedTrip.endDate,
            days: _buildDays(
              startDate: selectedTrip.startDate,
              endDate: selectedTrip.endDate,
            ),
            estimatedBudget: selectedTrip.estimatedBudget,
            notes: selectedTrip.notes,
          )
        : selectedTrip;
    if (_hasCurrentTrip) {
      _upcomingTrips.removeWhere((trip) => trip.id == _currentTrip.id);
      _upcomingTrips.add(_currentTrip);
    }
    _currentTrip = selected;
    _hasCurrentTrip = true;
    notifyListeners();
    return true;
  }

  bool isListingPlanned(String listingId) {
    if (!_hasCurrentTrip) return false;
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
    TimeOfDay? time,
    TimeOfDay? closingTime,
    int? travelMinutes,
    TripReservation? reservation,
    double? estimatedCost,
    String? notes,
  }) {
    if (!_hasCurrentTrip ||
        (estimatedCost != null &&
            (!estimatedCost.isFinite || estimatedCost < 0))) {
      return;
    }
    final updatedDays = [..._currentTrip.days];

    final selectedDay = updatedDays[dayIndex];

    final newExperience = TripExperience(
      id: '${_currentTrip.id}-$dayIndex-${selectedDay.title}-'
          '$listingId-${selectedDay.experiences.length + 1}',
      listingId: listingId,
      section: section,
      time: time,
      closingTime: closingTime,
      travelMinutes: travelMinutes,
      reservation: reservation,
      estimatedCost: estimatedCost,
      notes: _normalizeNote(notes),
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
      destinationId: _currentTrip.destinationId,
      startDate: _currentTrip.startDate,
      endDate: _currentTrip.endDate,
      days: updatedDays,
      estimatedBudget: _currentTrip.estimatedBudget,
      notes: _currentTrip.notes,
    );
    notifyListeners();
  }

  void updateExperienceDetails({
    required String experienceId,
    required double? estimatedCost,
    required String? notes,
  }) {
    if (!_hasCurrentTrip ||
        (estimatedCost != null && (!estimatedCost.isFinite || estimatedCost < 0))) {
      return;
    }
    var changed = false;
    final updatedDays = _currentTrip.days.map((day) {
      final experiences = day.experiences.map((experience) {
        if (experience.id != experienceId) return experience;
        final normalizedNote = _normalizeNote(notes);
        if (experience.estimatedCost == estimatedCost &&
            experience.notes == normalizedNote) {
          return experience;
        }
        changed = true;
        return experience.copyWith(
          estimatedCost: estimatedCost,
          notes: normalizedNote,
          clearEstimatedCost: estimatedCost == null,
          clearNotes: normalizedNote == null,
        );
      }).toList();
      return TripDay(title: day.title, date: day.date, experiences: experiences);
    }).toList();
    if (!changed) return;
    _currentTrip = Trip(
      id: _currentTrip.id,
      title: _currentTrip.title,
      destination: _currentTrip.destination,
      destinationId: _currentTrip.destinationId,
      startDate: _currentTrip.startDate,
      endDate: _currentTrip.endDate,
      days: updatedDays,
      estimatedBudget: _currentTrip.estimatedBudget,
      notes: _currentTrip.notes,
    );
    notifyListeners();
  }

  void setExperienceCompleted({
    required String experienceId,
    required bool completed,
  }) {
    if (!_hasCurrentTrip) return;
    var changed = false;
    final updatedDays = _currentTrip.days.map((day) {
      final updatedExperiences = day.experiences.map((experience) {
        if (experience.id != experienceId || experience.completed == completed) {
          return experience;
        }
        changed = true;
        return experience.copyWith(completed: completed);
      }).toList();
      return TripDay(
        title: day.title,
        date: day.date,
        experiences: updatedExperiences,
      );
    }).toList();

    if (!changed) return;
    _currentTrip = Trip(
      id: _currentTrip.id,
      title: _currentTrip.title,
      destination: _currentTrip.destination,
      destinationId: _currentTrip.destinationId,
      startDate: _currentTrip.startDate,
      endDate: _currentTrip.endDate,
      days: updatedDays,
      estimatedBudget: _currentTrip.estimatedBudget,
      notes: _currentTrip.notes,
    );
    notifyListeners();
  }

  bool removeExperience(String experienceId) {
    if (!_hasCurrentTrip) return false;
    var changed = false;
    final updatedDays = _currentTrip.days.map((day) {
      final experiences = day.experiences
          .where((experience) => experience.id != experienceId)
          .toList();
      if (experiences.length != day.experiences.length) changed = true;
      return TripDay(title: day.title, date: day.date, experiences: experiences);
    }).toList();
    if (!changed) return false;

    _currentTrip = _copyTrip(days: updatedDays);
    notifyListeners();
    return true;
  }

  Trip _copyTrip({required List<TripDay> days}) {
    return Trip(
      id: _currentTrip.id,
      title: _currentTrip.title,
      destination: _currentTrip.destination,
      destinationId: _currentTrip.destinationId,
      startDate: _currentTrip.startDate,
      endDate: _currentTrip.endDate,
      days: days,
      estimatedBudget: _currentTrip.estimatedBudget,
      notes: _currentTrip.notes,
    );
  }

  void updateNotes(String? notes) {
    if (!_hasCurrentTrip) return;
    final normalized = notes?.trim();
    final value = normalized == null || normalized.isEmpty ? null : normalized;
    if (_currentTrip.notes == value) return;
    _currentTrip = Trip(
      id: _currentTrip.id,
      title: _currentTrip.title,
      destination: _currentTrip.destination,
      destinationId: _currentTrip.destinationId,
      startDate: _currentTrip.startDate,
      endDate: _currentTrip.endDate,
      days: _currentTrip.days,
      estimatedBudget: _currentTrip.estimatedBudget,
      notes: value,
    );
    notifyListeners();
  }

  List<TripDay> _buildDays({
    required DateTime? startDate,
    required DateTime? endDate,
    List<TripDay> existingDays = const [],
  }) {
    if (startDate == null || endDate == null) {
      final dayCount = existingDays.isEmpty ? 1 : existingDays.length;
      return List.generate(dayCount, (index) {
        return TripDay(
          title: 'Day ${index + 1}',
          experiences: index < existingDays.length
              ? existingDays[index].experiences
              : const [],
        );
      });
    }

    final start = _dateOnly(startDate)!;
    final end = _dateOnly(endDate)!;
    final dayCount = end.difference(start).inDays + 1;
    final days = List.generate(dayCount, (index) {
      final date = start.add(Duration(days: index));
      return TripDay(
        title: 'Day ${index + 1}',
        date: date,
        experiences: index < existingDays.length
            ? existingDays[index].experiences
            : const [],
      );
    });

    if (existingDays.length > dayCount) {
      final overflow = existingDays
          .skip(dayCount)
          .expand((day) => day.experiences);
      final lastDay = days.last;
      days[dayCount - 1] = TripDay(
        title: lastDay.title,
        date: lastDay.date,
        experiences: [...lastDay.experiences, ...overflow],
      );
    }
    return days;
  }

  DateTime? _dateOnly(DateTime? date) {
    if (date == null) return null;
    return DateTime(date.year, date.month, date.day);
  }

  void _validateDateRange(DateTime? startDate, DateTime? endDate) {
    if ((startDate == null) != (endDate == null)) {
      throw ArgumentError('Trip start and end dates must both be set or empty.');
    }
    if (startDate != null && endDate != null && endDate.isBefore(startDate)) {
      throw ArgumentError('Trip end date cannot be before the start date.');
    }
  }

  String? _normalizeNote(String? note) {
    final normalized = note?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }
}
