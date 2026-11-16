import 'package:flutter/material.dart';

import 'trip_section.dart';

/// Explains when a selected clock time falls outside its broad itinerary slot.
/// These are planning hints, so mismatches remain editable by the traveler.
class TripScheduleValidation {
  const TripScheduleValidation._();

  static String? warningFor(TripSection? section, TimeOfDay? time) {
    if (section == null || time == null) return null;
    final minutes = time.hour * 60 + time.minute;
    final fits = switch (section) {
      TripSection.morning => minutes >= 5 * 60 && minutes < 12 * 60,
      TripSection.afternoon => minutes >= 12 * 60 && minutes < 18 * 60,
      TripSection.evening => minutes >= 18 * 60,
    };
    if (fits) return null;
    final label = switch (section) {
      TripSection.morning => 'morning',
      TripSection.afternoon => 'afternoon',
      TripSection.evening => 'evening',
    };
    return 'This time may not fit the $label part of your day. You can change the time or section.';
  }
}
