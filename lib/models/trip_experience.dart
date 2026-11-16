import 'package:flutter/material.dart';

import 'trip_reservation.dart';
import 'trip_section.dart';

class TripExperience {
  static const int schemaVersion = 1;
  final String id;
  final String listingId;
  final TripSection section;
  final TimeOfDay? time;
  /// Optional closing time entered by the traveler from venue information.
  final TimeOfDay? closingTime;
  final double? estimatedCost;
  final TripReservation? reservation;

  /// If null, use the trip's traveler count.
  final int? travelerCountOverride;

  final String? notes;
  final bool completed;

  /// Estimated travel time to this experience.
  /// Null means the travel time is not known yet.
  final int? travelMinutes;

  /// Extra time the traveler should arrive before the scheduled time.
  /// Defaults to 10 minutes.
  final int arrivalBufferMinutes;

  const TripExperience({
    required this.id,
    required this.listingId,
    required this.section,
    this.time,
    this.closingTime,
    this.estimatedCost,
    this.travelerCountOverride,
    this.notes,
    this.completed = false,
    this.travelMinutes,
    this.arrivalBufferMinutes = 10,
    this.reservation,
  });

  Map<String, Object?> toJson() => {
    'schemaVersion': schemaVersion,
    'id': id,
    'listingId': listingId,
    'section': section.name,
    'time': _timeToJson(time),
    'closingTime': _timeToJson(closingTime),
    'estimatedCost': estimatedCost,
    'travelerCountOverride': travelerCountOverride,
    'notes': notes,
    'completed': completed,
    'travelMinutes': travelMinutes,
    'arrivalBufferMinutes': arrivalBufferMinutes,
    'reservation': reservation?.toJson(),
  };

  factory TripExperience.fromJson(Map<String, Object?> json) {
    final version = (json['schemaVersion'] as num?)?.toInt() ?? 1;
    if (version != schemaVersion) {
      throw FormatException('Unsupported TripExperience schema version: $version');
    }
    final sectionName = json['section'] as String? ?? TripSection.morning.name;
    final section = TripSection.values.where((value) => value.name == sectionName);
    if (section.isEmpty) throw FormatException('Unknown trip section: $sectionName');
    final reservationJson = json['reservation'];
    return TripExperience(
      id: _requiredExperienceString(json, 'id'),
      listingId: _requiredExperienceString(json, 'listingId'),
      section: section.first,
      time: _timeFromJson(json['time']),
      closingTime: _timeFromJson(json['closingTime']),
      estimatedCost: (json['estimatedCost'] as num?)?.toDouble(),
      travelerCountOverride: (json['travelerCountOverride'] as num?)?.toInt(),
      notes: json['notes'] as String?,
      completed: json['completed'] as bool? ?? false,
      travelMinutes: (json['travelMinutes'] as num?)?.toInt(),
      arrivalBufferMinutes: (json['arrivalBufferMinutes'] as num?)?.toInt() ?? 10,
      reservation: reservationJson == null
          ? null
          : TripReservation.fromJson(Map<String, Object?>.from(reservationJson as Map)),
    );
  }

  TripExperience copyWith({
    String? id,
    String? listingId,
    TripSection? section,
    TimeOfDay? time,
    TimeOfDay? closingTime,
    double? estimatedCost,
    int? travelerCountOverride,
    String? notes,
    bool? completed,
    int? travelMinutes,
    int? arrivalBufferMinutes,
    TripReservation? reservation,
    bool clearEstimatedCost = false,
    bool clearNotes = false,
  }) {
    return TripExperience(
      id: id ?? this.id,
      listingId: listingId ?? this.listingId,
      section: section ?? this.section,
      time: time ?? this.time,
      closingTime: closingTime ?? this.closingTime,
      estimatedCost: clearEstimatedCost ? null : estimatedCost ?? this.estimatedCost,
      travelerCountOverride:
          travelerCountOverride ?? this.travelerCountOverride,
      notes: clearNotes ? null : notes ?? this.notes,
      completed: completed ?? this.completed,
      travelMinutes: travelMinutes ?? this.travelMinutes,
      arrivalBufferMinutes: arrivalBufferMinutes ?? this.arrivalBufferMinutes,
      reservation: reservation ?? this.reservation,
    );
  }
}

String _requiredExperienceString(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! String || value.isEmpty) {
    throw FormatException('TripExperience.$key must be a non-empty string.');
  }
  return value;
}

Map<String, int>? _timeToJson(TimeOfDay? value) => value == null
    ? null
    : {'hour': value.hour, 'minute': value.minute};

TimeOfDay? _timeFromJson(Object? value) {
  if (value == null) return null;
  final json = Map<String, Object?>.from(value as Map);
  return TimeOfDay(hour: (json['hour'] as num).toInt(), minute: (json['minute'] as num).toInt());
}
