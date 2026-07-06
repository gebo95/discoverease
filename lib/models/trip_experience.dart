import 'package:flutter/material.dart';

import 'trip_section.dart';

class TripExperience {
  final String id;

  final String listingId;

  final TripSection section;

  final TimeOfDay? time;

  final double? estimatedCost;

  /// If null, use the trip's traveler count.
  final int? travelerCountOverride;

  final String? notes;

  final bool completed;

  const TripExperience({
    required this.id,
    required this.listingId,
    required this.section,
    this.time,
    this.estimatedCost,
    this.travelerCountOverride,
    this.notes,
    this.completed = false,
  });

  TripExperience copyWith({
    String? id,
    String? listingId,
    TripSection? section,
    TimeOfDay? time,
    double? estimatedCost,
    int? travelerCountOverride,
    String? notes,
    bool? completed,
  }) {
    return TripExperience(
      id: id ?? this.id,
      listingId: listingId ?? this.listingId,
      section: section ?? this.section,
      time: time ?? this.time,
      estimatedCost: estimatedCost ?? this.estimatedCost,
      travelerCountOverride:
          travelerCountOverride ?? this.travelerCountOverride,
      notes: notes ?? this.notes,
      completed: completed ?? this.completed,
    );
  }
}
