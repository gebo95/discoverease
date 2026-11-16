import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/business_profile.dart';

/// Admin-only moderation operations. Firestore Rules independently enforce
/// the admin custom claim; hiding the UI is not an authorization boundary.
class FirebaseAdminReviewService {
  FirebaseAdminReviewService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

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
          'imageUrl': currentExperience.imageUrl,
          'gallery': <String>[],
          'rating': null,
          'reviewCount': 0,
          'price': currentExperience.price,
          'status': 'published',
          'displayStatus': 'New',
          'description': currentExperience.description,
          'whyYoullLoveIt': '',
          'perfectFor': <String>[],
          'features': <String>[],
          'pairedListingIds': <String>[],
          'continueDayIds': <String>[],
          'publishedAt': FieldValue.serverTimestamp(),
        });
      } else {
        transaction.delete(catalogRef);
      }
    });
  }
}
