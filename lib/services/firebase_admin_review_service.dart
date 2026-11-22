import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/business_profile.dart';

/// Admin-only moderation operations. Firestore Rules independently enforce
/// the admin custom claim; hiding the UI is not an authorization boundary.
class FirebaseAdminReviewService {
  FirebaseAdminReviewService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _functions =
           functions ?? FirebaseFunctions.instanceFor(region: 'us-central1');

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  /// Copies a submission's (or proposed change's) new photos from the private
  /// folder to the public one and returns their public addresses, cover first.
  /// Nothing about the experience changes until the review is saved.
  Future<List<String>> _publishPhotos(
    String businessId,
    String experienceId,
  ) async {
    try {
      final result = await _functions
          .httpsCallable('publishExperiencePhotos')
          .call({'businessId': businessId, 'experienceId': experienceId});
      final data = Map<String, Object?>.from(result.data as Map);
      return (data['photos'] as List).cast<String>();
    } on FirebaseFunctionsException catch (error) {
      throw StateError(error.message ?? 'Could not publish the photos.');
    }
  }

  Future<bool> isAdmin({bool refresh = false}) async {
    final user = _auth.currentUser;
    if (user == null) return false;
    final token = await user.getIdTokenResult(refresh);
    return token.claims?['admin'] == true;
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchPendingBusinesses() =>
      _firestore
          .collection('businesses')
          .where('status', isEqualTo: 'pending_review')
          .snapshots();

  Stream<QuerySnapshot<Map<String, dynamic>>> watchPendingExperiences() =>
      _firestore
          .collectionGroup('experiences')
          .where('status', isEqualTo: 'pending_review')
          .snapshots();

  /// Proposed changes to experiences that are already live. Needs a
  /// collection-group index on `revisionStatus` (Firestore prints a one-click
  /// link to create it the first time this query runs).
  Stream<QuerySnapshot<Map<String, dynamic>>> watchPendingRevisions() =>
      _firestore
          .collectionGroup('experiences')
          .where('revisionStatus', isEqualTo: 'pending_review')
          .snapshots();

  Future<void> reviewBusiness(String businessId, {required bool approve}) async {
    await _firestore.collection('businesses').doc(businessId).update({
      'status': approve ? 'published' : 'rejected',
      'verified': approve,
      'reviewedAt': FieldValue.serverTimestamp(),
      'reviewedBy': _auth.currentUser?.uid,
    });
  }

  Future<void> reviewExperience({
    required String businessId,
    required BusinessExperience experience,
    required bool approve,
    String reviewNote = '',
  }) async {
    if (!approve && reviewNote.trim().isEmpty) {
      throw StateError('Add a reason before rejecting an experience.');
    }
    final business = _firestore.collection('businesses').doc(businessId);
    final experienceRef = business.collection('experiences').doc(experience.id);
    final catalogRef = _firestore.collection('catalog').doc(experience.id);
    // Photos are copied to the public folder first; the decision below only
    // records them once the business and experience checks pass.
    final List<String>? publishedPhotos =
        approve && experience.photos.isNotEmpty
        ? await _publishPhotos(businessId, experience.id)
        : null;
    await _firestore.runTransaction((transaction) async {
      final businessSnapshot = await transaction.get(business);
      final experienceSnapshot = await transaction.get(experienceRef);
      if (!businessSnapshot.exists) {
        throw StateError('The business profile no longer exists.');
      }
      if (!experienceSnapshot.exists) {
        throw StateError('This experience no longer exists.');
      }
      final businessData = businessSnapshot.data()!;
      if (approve && businessData['status'] != 'published') {
        throw StateError('Approve the business profile before publishing experiences.');
      }
      if (experienceSnapshot.data()?['status'] != 'pending_review') {
        throw StateError('This experience is no longer awaiting review.');
      }
      final currentExperience = BusinessExperience.fromJson({
        ...Map<String, Object?>.from(experienceSnapshot.data()!),
        'id': experience.id,
      });

      transaction.update(experienceRef, {
        'status': approve ? 'published' : 'rejected',
        'reviewNote': approve ? '' : reviewNote.trim(),
        'reviewedAt': FieldValue.serverTimestamp(),
        'reviewedBy': _auth.currentUser?.uid,
        if (publishedPhotos != null) ...{
          'photos': publishedPhotos,
          'imageUrl': publishedPhotos.isEmpty ? '' : publishedPhotos.first,
        },
      });
      if (approve) {
        transaction.set(catalogRef, {
          'schemaVersion': 1,
          'id': experience.id,
          'sourceExperienceId': experience.id,
          'businessId': businessId,
          'businessName': businessData['name'] as String? ?? '',
          'title': currentExperience.title,
          'subtitle': businessData['name'] as String? ?? '',
          'category': currentExperience.category,
          'subcategory': currentExperience.subcategory,
          'destinationId': currentExperience.destinationId,
          'destination': currentExperience.destination,
          'location': currentExperience.location,
          'address': currentExperience.address,
          'website': currentExperience.website,
          'bookingUrl': currentExperience.bookingUrl,
          'phone': currentExperience.phone,
          'hours': currentExperience.hours,
          'schedule': currentExperience.schedule,
          'imageUrl': publishedPhotos != null && publishedPhotos.isNotEmpty
              ? publishedPhotos.first
              : currentExperience.imageUrl,
          'gallery': publishedPhotos != null && publishedPhotos.length > 1
              ? publishedPhotos.sublist(1)
              : <String>[],
          'rating': null,
          'reviewCount': 0,
          'price': currentExperience.price,
          'status': 'published',
          'displayStatus': 'New',
          'description': currentExperience.description,
          'whyYoullLoveIt': currentExperience.whyYoullLoveIt,
          'perfectFor': currentExperience.perfectFor,
          'features': currentExperience.features,
          'latitude': ?currentExperience.latitude,
          'longitude': ?currentExperience.longitude,
          'highlight': currentExperience.highlight,
          'pairedListingIds': <String>[],
          'continueDayIds': <String>[],
          'publishedAt': FieldValue.serverTimestamp(),
        });
      } else {
        transaction.delete(catalogRef);
      }
    });
  }

  /// Approves or rejects a proposed change to a live experience. Approving
  /// copies the new content to the experience and its public catalog entry in
  /// one step; rejecting leaves everything live as it was.
  Future<void> reviewRevision({
    required String businessId,
    required String experienceId,
    required bool approve,
    String note = '',
  }) async {
    if (!approve && note.trim().isEmpty) {
      throw StateError('Add a reason before rejecting these changes.');
    }
    final business = _firestore.collection('businesses').doc(businessId);
    final experienceRef = business.collection('experiences').doc(experienceId);
    final catalogRef = _firestore.collection('catalog').doc(experienceId);
    // If the proposal includes photos, copy any new ones to the public folder
    // first. The transaction below checks the proposal did not change meanwhile.
    List<String>? publishedPhotos;
    List<Object?>? requestedPhotos;
    if (approve) {
      final proposal = (await experienceRef.get()).data()?['pendingRevision'];
      if (proposal is Map && proposal['photos'] is List) {
        requestedPhotos = List<Object?>.from(proposal['photos'] as List);
        publishedPhotos = requestedPhotos.isEmpty
            ? <String>[]
            : await _publishPhotos(businessId, experienceId);
      }
    }
    await _firestore.runTransaction((transaction) async {
      final businessSnapshot = await transaction.get(business);
      final experienceSnapshot = await transaction.get(experienceRef);
      final catalogSnapshot = await transaction.get(catalogRef);
      if (!experienceSnapshot.exists) {
        throw StateError('This experience no longer exists.');
      }
      final data = experienceSnapshot.data()!;
      if (data['status'] != 'published') {
        throw StateError('Only live experiences have changes to review.');
      }
      if (data['revisionStatus'] != 'pending_review' ||
          data['pendingRevision'] is! Map) {
        throw StateError('These changes are no longer awaiting review.');
      }
      final reviewer = _auth.currentUser?.uid;
      if (!approve) {
        transaction.update(experienceRef, {
          'revisionStatus': 'rejected',
          'revisionNote': note.trim(),
          'reviewedAt': FieldValue.serverTimestamp(),
          'reviewedBy': reviewer,
        });
        return;
      }
      if (!businessSnapshot.exists ||
          businessSnapshot.data()?['status'] != 'published') {
        throw StateError('The business profile is not approved.');
      }
      if (!catalogSnapshot.exists) {
        throw StateError(
          'The public listing for this experience is missing, so the changes cannot be applied.',
        );
      }
      final revision = ExperienceRevision.fromJson(
        Map<String, Object?>.from(data['pendingRevision'] as Map),
      );
      // A proposal without a pin removes any pin the listing had.
      final content = {
        ...revision.toJson(),
        if (revision.latitude == null || revision.longitude == null) ...{
          'latitude': FieldValue.delete(),
          'longitude': FieldValue.delete(),
        },
      };
      final photosNow = (data['pendingRevision'] as Map)['photos'];
      if (requestedPhotos != null &&
          (photosNow is! List ||
              photosNow.length != requestedPhotos.length ||
              !Iterable<int>.generate(
                requestedPhotos.length,
              ).every((i) => photosNow[i] == requestedPhotos![i]))) {
        throw StateError(
          'The proposed photos changed while you were reviewing. Open the review again.',
        );
      }
      final photoFields = <String, Object?>{
        if (publishedPhotos != null) ...{
          'photos': publishedPhotos,
          'imageUrl': publishedPhotos.isEmpty ? '' : publishedPhotos.first,
        },
      };
      transaction.update(experienceRef, {
        // A proposal from before photos existed has no photo list; it must
        // not wipe the photos the experience already has.
        ...(Map<String, Object?>.of(content)..remove('photos')),
        ...photoFields,
        'pendingRevision': FieldValue.delete(),
        'revisionStatus': FieldValue.delete(),
        'revisionNote': FieldValue.delete(),
        'revisionSubmittedAt': FieldValue.delete(),
        'reviewNote': '',
        'reviewedAt': FieldValue.serverTimestamp(),
        'reviewedBy': reviewer,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      // Only the reviewed content changes; publishedAt, ratings and the rest
      // of the public listing are left alone.
      transaction.update(catalogRef, {
        ...(Map<String, Object?>.of(content)
          ..remove('photos')
          ..remove('imageUrl')),
        if (publishedPhotos != null) ...{
          'imageUrl': publishedPhotos.isEmpty ? '' : publishedPhotos.first,
          'gallery': publishedPhotos.length > 1
              ? publishedPhotos.sublist(1)
              : <String>[],
        },
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }
}
