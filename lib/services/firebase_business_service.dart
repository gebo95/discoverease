import 'package:cloud_firestore/cloud_firestore.dart';

import '../shared/utils/web_link.dart';
import '../models/business_profile.dart';

/// Firestore operations for owner-submitted business profiles and experiences.
/// Publishing remains an admin review action enforced by Firestore Rules.
class FirebaseBusinessService {
  FirebaseBusinessService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _business(String uid) =>
      _firestore.collection('businesses').doc(uid);

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchBusiness(String uid) =>
      _business(uid).snapshots();

  Stream<QuerySnapshot<Map<String, dynamic>>> watchExperiences(String uid) =>
      _business(uid).collection('experiences').snapshots();

  Stream<QuerySnapshot<Map<String, dynamic>>> watchDailyAnalytics({
    required String businessId,
    required String listingId,
    required int days,
  }) {
    final now = DateTime.now().toUtc();
    final today = DateTime.utc(now.year, now.month, now.day);
    final firstDay = today.subtract(Duration(days: days - 1));
    return _business(businessId)
        .collection('analytics')
        .doc(listingId)
        .collection('daily')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(firstDay))
        .orderBy('date')
        .snapshots();
  }

  /// Lifetime per-listing figures (for example unique sharers). The document
  /// may not exist until the first share is recorded.
  Stream<DocumentSnapshot<Map<String, dynamic>>> watchAnalyticsSummary({
    required String businessId,
    required String listingId,
  }) => _business(businessId).collection('analytics').doc(listingId).snapshots();

  Future<void> createBusiness({
    required String uid,
    required String name,
    required String email,
    required String phone,
    required String website,
    required String instagram,
  }) async {
    final reference = _business(uid);
    final existing = await reference.get();
    if (existing.exists) {
      throw StateError('A business profile already exists for this account.');
    }
    await reference.set({
      'schemaVersion': BusinessProfile.schemaVersion,
      'id': uid,
      'ownerUid': uid,
      'name': name.trim(),
      'email': email.trim(),
      'phone': phone.trim(),
      'website': website.trim(),
      'instagram': instagram.trim(),
      'status': 'pending_review',
      'verified': false,
      'subscriptionTier': 'free',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<String> submitExperience({
    required String uid,
    required String title,
    required String description,
    required String category,
    required String subcategory,
    required String destinationId,
    required String destination,
    required String location,
    required String price,
    required String imageUrl,
    String address = '',
    String website = '',
    String bookingUrl = '',
    String phone = '',
    String hours = '',
    String schedule = '',
  }) async {
    final reference = _business(uid).collection('experiences').doc();
    final experience = BusinessExperience(
      id: reference.id,
      title: title.trim(),
      description: description.trim(),
      category: category.trim(),
      subcategory: subcategory.trim(),
      destinationId: destinationId,
      destination: destination,
      location: location.trim(),
      price: price.trim(),
      imageUrl: imageUrl.trim(),
      status: 'pending_review',
      address: address.trim(),
      website: normalizeWebLink(website),
      bookingUrl: normalizeWebLink(bookingUrl),
      phone: phone.trim(),
      hours: hours.trim(),
      schedule: schedule.trim(),
    );
    await reference.set({
      ...experience.toJson(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return reference.id;
  }

  /// Updates an in-review experience or resubmits a rejected one.
  /// Published records are read-only here so their public catalog copy cannot
  /// drift from the moderated submission.
  /// Proposes changes to a live experience. The live version keeps showing
  /// to travelers until an admin approves the revision.
  Future<void> submitRevision({
    required String uid,
    required String experienceId,
    required ExperienceRevision revision,
  }) async {
    final reference = _business(uid).collection('experiences').doc(experienceId);
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(reference);
      if (!snapshot.exists) {
        throw StateError('This experience no longer exists.');
      }
      if (snapshot.data()?['status'] != 'published') {
        throw StateError('Only live experiences use review for changes.');
      }
      transaction.update(reference, {
        'pendingRevision': revision.normalized().toJson(),
        'revisionStatus': 'pending_review',
        'revisionNote': '',
        'revisionSubmittedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  /// Withdraws a pending revision or discards a rejected one. The live
  /// experience is not touched.
  Future<void> withdrawRevision({
    required String uid,
    required String experienceId,
  }) => _business(uid).collection('experiences').doc(experienceId).update({
    'pendingRevision': FieldValue.delete(),
    'revisionStatus': FieldValue.delete(),
    'revisionNote': FieldValue.delete(),
    'revisionSubmittedAt': FieldValue.delete(),
    'updatedAt': FieldValue.serverTimestamp(),
  });

  Future<void> updateExperience({
    required String uid,
    required BusinessExperience experience,
  }) async {
    final reference = _business(uid)
        .collection('experiences')
        .doc(experience.id);
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(reference);
      if (!snapshot.exists) {
        throw StateError('This experience no longer exists.');
      }
      final status = snapshot.data()?['status'];
      if (status != 'pending_review' && status != 'rejected') {
        throw StateError('Published experiences cannot be edited here.');
      }
      final resubmitting = status == 'rejected';
      transaction.update(reference, {
        'title': experience.title.trim(),
        'description': experience.description.trim(),
        'category': experience.category.trim(),
        'subcategory': experience.subcategory.trim(),
        'destinationId': experience.destinationId,
        'destination': experience.destination,
        'location': experience.location.trim(),
        'price': experience.price.trim(),
        'imageUrl': experience.imageUrl.trim(),
        'address': experience.address.trim(),
        'website': normalizeWebLink(experience.website),
        'bookingUrl': normalizeWebLink(experience.bookingUrl),
        'phone': experience.phone.trim(),
        'hours': experience.hours.trim(),
        'schedule': experience.schedule.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
        if (resubmitting) ...{
          'status': 'pending_review',
          'reviewNote': '',
          'reviewedAt': null,
          'reviewedBy': null,
        },
      });
    });
  }
}
