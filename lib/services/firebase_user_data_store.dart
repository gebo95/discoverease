import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/saved_experience.dart';
import '../models/trip.dart';

class AccountCloudData {
  const AccountCloudData({
    required this.currentTrip,
    required this.upcomingTrips,
    required this.savedExperiences,
  });

  final Trip? currentTrip;
  final List<Trip> upcomingTrips;
  final List<SavedExperience> savedExperiences;
}

/// User-owned Firestore persistence for trips and saved experiences.
class FirebaseUserDataStore {
  FirebaseUserDataStore({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _trips(String uid) =>
      _firestore.collection('users').doc(uid).collection('trips');

  CollectionReference<Map<String, dynamic>> _saved(String uid) =>
      _firestore.collection('users').doc(uid).collection('saved');

  Future<AccountCloudData> load(String uid) async {
    final tripSnapshot = await _trips(uid).get();
    Trip? current;
    final upcoming = <Trip>[];
    for (final document in tripSnapshot.docs) {
      final data = Map<String, Object?>.from(document.data());
      final lifecycle = data.remove('lifecycle') as String? ?? 'upcoming';
      final trip = Trip.fromJson(data);
      if (lifecycle == 'current' && current == null) {
        current = trip;
      } else if (lifecycle == 'upcoming') {
        upcoming.add(trip);
      }
    }

    final savedSnapshot = await _saved(uid).get();
    final saved = savedSnapshot.docs
        .map(
          (document) => SavedExperience.fromJson(
            Map<String, Object?>.from(document.data()),
          ),
        )
        .toList(growable: false);

    return AccountCloudData(
      currentTrip: current,
      upcomingTrips: upcoming,
      savedExperiences: saved,
    );
  }

  /// Replaces the user's trip set with the current repository snapshot.
  /// Demo trips never reach this method because account data is hydrated first.
  Future<void> replaceTrips(
    String uid, {
    required Trip? current,
    required List<Trip> upcoming,
  }) async {
    final collection = _trips(uid);
    final existing = await collection.get();
    final desired = <String, Map<String, Object?>>{};
    if (current != null) desired[current.id] = _tripDocument(current, 'current');
    for (final trip in upcoming) {
      desired[trip.id] = _tripDocument(trip, 'upcoming');
    }

    final stale = existing.docs
        .where((document) => !desired.containsKey(document.id))
        .toList(growable: false);
    if (stale.length + desired.length > 500) {
      throw StateError('Too many trips to save in one operation.');
    }
    final batch = _firestore.batch();
    for (final document in stale) {
      batch.delete(document.reference);
    }
    for (final entry in desired.entries) {
      batch.set(collection.doc(entry.key), entry.value);
    }
    await batch.commit();
  }

  /// Replaces the user's saved collection with the repository snapshot.
  Future<void> replaceSaved(String uid, List<SavedExperience> saved) async {
    final collection = _saved(uid);
    final existing = await collection.get();
    final desired = {for (final item in saved) item.listingId: item};
    final stale = existing.docs
        .where((document) => !desired.containsKey(document.id))
        .toList(growable: false);
    if (stale.length + desired.length > 500) {
      throw StateError('Too many saved places to save in one operation.');
    }
    final batch = _firestore.batch();
    for (final document in stale) {
      batch.delete(document.reference);
    }
    for (final entry in desired.entries) {
      batch.set(collection.doc(entry.key), entry.value.toJson());
    }
    await batch.commit();
  }

  Map<String, Object?> _tripDocument(Trip trip, String lifecycle) => {
    ...trip.toJson(),
    'lifecycle': lifecycle,
  };
}
