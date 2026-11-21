import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/listing.dart';
import '../models/trip.dart';
import '../repositories/listing_repository.dart';
import '../repositories/saved_repository.dart';
import '../repositories/trip_repository.dart';

/// Keeps the public `unavailable` notices for the places this traveler saved
/// or planned. When a business hides, ends or removes a listing, the traveler
/// still sees it (greyed out, with the reason) instead of it silently
/// vanishing from their saved places and trips.
///
/// Only the notices for the traveler's own saved and planned listing ids are
/// watched, so this stays small however many listings are unavailable overall.
class FirebaseUnavailabilitySyncService {
  FirebaseUnavailabilitySyncService({
    required this._listings,
    required this._saved,
    required this._trips,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Firestore allows at most 30 values in a `whereIn` filter.
  static const int chunkSize = 30;

  final ListingRepository _listings;
  final SavedRepository _saved;
  final TripRepository _trips;
  final FirebaseFirestore _firestore;

  Set<String> _watched = const {};
  final List<StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>
  _subscriptions = [];
  final Map<int, List<Listing>> _byChunk = {};
  bool _started = false;

  void start() {
    if (_started) return;
    _started = true;
    _saved.addListener(_refresh);
    _trips.addListener(_refresh);
    _refresh();
  }

  /// Every listing id the traveler has saved or put in a trip.
  @visibleForTesting
  static Set<String> collectListingIds({
    required Iterable<String> savedIds,
    required Iterable<Trip> trips,
  }) {
    return {
      ...savedIds,
      for (final trip in trips)
        for (final day in trip.days)
          for (final experience in day.experiences) experience.listingId,
    }..removeWhere((id) => id.isEmpty || id.contains('/'));
  }

  /// Splits ids into groups small enough for one Firestore query each.
  @visibleForTesting
  static List<List<String>> chunk(Iterable<String> ids) {
    final sorted = ids.toList()..sort();
    return [
      for (var i = 0; i < sorted.length; i += chunkSize)
        sorted.sublist(
          i,
          i + chunkSize > sorted.length ? sorted.length : i + chunkSize,
        ),
    ];
  }

  void _refresh() {
    final ids = collectListingIds(
      savedIds: _saved.getAllSaved().map((item) => item.listingId),
      trips: [
        if (_trips.hasCurrentTrip) _trips.getCurrentTrip(),
        ..._trips.getUpcomingTrips(),
        ..._trips.getMemories(),
      ],
    );
    if (setEquals(ids, _watched)) return;
    _watched = ids;
    _resubscribe();
  }

  void _resubscribe() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();
    _byChunk.clear();
    _publish();

    final groups = chunk(_watched);
    for (var index = 0; index < groups.length; index++) {
      final chunkIndex = index;
      _subscriptions.add(
        _firestore
            .collection('unavailable')
            .where(FieldPath.documentId, whereIn: groups[index])
            .snapshots()
            .listen(
              (snapshot) {
                _byChunk[chunkIndex] = [
                  for (final document in snapshot.docs)
                    Listing.fromUnavailableJson({
                      ...Map<String, Object?>.from(document.data()),
                      'listingId': document.id,
                    }),
                ];
                _publish();
              },
              onError: (Object _) {
                // Keep what we last knew; saved places still show normally.
              },
            ),
      );
    }
  }

  bool _publishedAny = false;

  void _publish() {
    final all = _byChunk.values.expand((l) => l).toList(growable: false);
    // Nothing to say and nothing said before: skip, so starting up never
    // asks the app to rebuild while it is still building.
    if (all.isEmpty && !_publishedAny) return;
    _publishedAny = all.isNotEmpty;
    _listings.setUnavailableListings(all);
  }

  void dispose() {
    _saved.removeListener(_refresh);
    _trips.removeListener(_refresh);
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();
  }
}
