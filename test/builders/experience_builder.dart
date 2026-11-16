import 'package:flutter/material.dart';

import 'package:discoverease/models/trip_experience.dart';
import 'package:discoverease/models/trip_section.dart';
import 'package:discoverease/models/trip_reservation.dart';

class ExperienceBuilder {
  String _id = 'experience-1';
  String _listingId = 'listing-1';
  TripSection _section = TripSection.morning;
  TimeOfDay? _time;
  TimeOfDay? _closingTime;
  bool _completed = false;
  int? _travelMinutes;
  int _arrivalBuffer = 10;
  double? _estimatedCost;
  int? _travelerCountOverride;
  String? _notes;
  TripReservation? _reservation;

  ExperienceBuilder id(String id) {
    _id = id;
    return this;
  }

  ExperienceBuilder morning() {
    _section = TripSection.morning;
    return this;
  }

  ExperienceBuilder afternoon() {
    _section = TripSection.afternoon;
    return this;
  }

  ExperienceBuilder evening() {
    _section = TripSection.evening;
    return this;
  }

  ExperienceBuilder listing(String listingId) {
    _listingId = listingId;
    return this;
  }

  ExperienceBuilder section(TripSection section) {
    _section = section;
    return this;
  }

  ExperienceBuilder at(int hour, int minute) {
    _time = TimeOfDay(hour: hour, minute: minute);
    return this;
  }

  ExperienceBuilder closesAt(int hour, int minute) {
    _closingTime = TimeOfDay(hour: hour, minute: minute);
    return this;
  }

  ExperienceBuilder closingTime(int hour, int minute) => closesAt(hour, minute);

  ExperienceBuilder travelTime(int minutes) {
    _travelMinutes = minutes;
    return this;
  }

  ExperienceBuilder arrivalBuffer(int minutes) {
    _arrivalBuffer = minutes;
    return this;
  }

  ExperienceBuilder completed() {
    _completed = true;
    return this;
  }

  ExperienceBuilder cost(double cost) {
    _estimatedCost = cost;
    return this;
  }

  ExperienceBuilder notes(String notes) {
    _notes = notes;
    return this;
  }

  ExperienceBuilder withReservation({
    TripReservationType type = TripReservationType.attraction,
    String? confirmationNumber,
    String? ticketUrl,
    DateTime? reminderTime,
  }) {
    _reservation = TripReservation(
      type: type,
      confirmationNumber: confirmationNumber,
      ticketUrl: ticketUrl,
      reminderTime: reminderTime,
    );

    return this;
  }

  TripExperience build() {
    return TripExperience(
      id: _id,
      listingId: _listingId,
      section: _section,
      time: _time,
      closingTime: _closingTime,
      completed: _completed,
      travelMinutes: _travelMinutes,
      arrivalBufferMinutes: _arrivalBuffer,
      estimatedCost: _estimatedCost,
      travelerCountOverride: _travelerCountOverride,
      notes: _notes,
      reservation: _reservation,
    );
  }
}
