import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/listing.dart';
import '../repositories/listing_repository.dart';

/// Keeps the public Firestore catalog mirrored into the existing discovery repo.
/// Local curated listings remain available if the cloud stream is empty/offline.
class FirebaseCatalogSyncService {
  FirebaseCatalogSyncService({
    required this._listings,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final ListingRepository _listings;
  final FirebaseFirestore _firestore;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subscription;

  void start() {
    _subscription ??= _firestore
        .collection('catalog')
        .where('status', isEqualTo: 'published')
        .snapshots()
        .listen(
          (snapshot) {
            final entries = <Listing>[];
            for (final document in snapshot.docs) {
              try {
                entries.add(
                  Listing.fromCatalogJson({
                    ...Map<String, Object?>.from(document.data()),
                    'id': document.id,
                  }),
                );
              } on FormatException {
                // Ignore malformed documents; the rest of the catalog remains usable.
              }
            }
            _listings.setPublishedListings(entries);
          },
          onError: (Object _) {
            // Keep the last known catalog and local curated data on transient errors.
          },
        );
  }

  void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }
}
