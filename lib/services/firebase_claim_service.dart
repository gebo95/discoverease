import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../models/claimable_business.dart';

/// Claiming a business: find it, get a code at the contact on file, type the
/// code. The server creates, emails and checks the codes; the app never sees
/// one. Admin methods fail on the server unless the caller is an admin.
class FirebaseClaimService {
  FirebaseClaimService({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _functions =
           functions ?? FirebaseFunctions.instanceFor(region: 'us-central1');

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  Stream<List<ClaimableBusiness>> watchClaimable() => _firestore
      .collection('claimable')
      .limit(500)
      .snapshots()
      .map(
        (snapshot) =>
            [
              for (final doc in snapshot.docs)
                ?ClaimableBusiness.fromJson(
                  doc.id,
                  Map<String, Object?>.from(doc.data()),
                ),
            ]..sort(
              (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
            ),
      );

  /// Sends a code to the contact on file. Returns where it went, masked.
  Future<String> requestCode(String businessId) async {
    final data = await _call('requestClaimCode', {'businessId': businessId});
    return data['sentTo'] as String? ?? '';
  }

  Future<void> confirmCode({
    required String businessId,
    required String code,
  }) => _call('confirmClaimCode', {
    'businessId': businessId,
    'code': code.trim(),
  });

  /// "I can't get the code": an admin reviews it.
  Future<void> submitRequest({
    required String businessId,
    required String contact,
    String note = '',
  }) => _call('submitClaimRequest', {
    'businessId': businessId,
    'contact': contact.trim(),
    'note': note.trim(),
  });

  // ---- admin ----

  Future<void> createClaimable({
    required String name,
    required String email,
    String phone = '',
    String category = '',
    String destinationId = '',
  }) => _call('createClaimableBusiness', {
    'name': name.trim(),
    'email': email.trim(),
    'phone': phone.trim(),
    'category': category.trim(),
    'destinationId': destinationId.trim(),
  });

  Stream<List<ClaimRequest>> watchPendingRequests() => _firestore
      .collection('claim_requests')
      .where('status', isEqualTo: 'pending')
      .limit(100)
      .snapshots()
      .map(
        (snapshot) => [
          for (final doc in snapshot.docs)
            ?ClaimRequest.fromJson(
              doc.id,
              Map<String, Object?>.from(doc.data()),
            ),
        ],
      );

  Future<void> reviewRequest({
    required String requestId,
    required bool approve,
    String note = '',
  }) => _call('reviewClaimRequest', {
    'requestId': requestId,
    'approve': approve,
    'note': note.trim(),
  });

  /// Businesses that were claimed (admin only).
  Stream<List<ClaimedBusiness>> watchClaimedBusinesses() => _firestore
      .collection('businesses')
      .where('claimStatus', isEqualTo: 'claimed')
      .limit(200)
      .snapshots()
      .map(
        (snapshot) =>
            [
              for (final doc in snapshot.docs)
                ?ClaimedBusiness.fromJson(
                  doc.id,
                  Map<String, Object?>.from(doc.data()),
                ),
            ]..sort(
              (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
            ),
      );

  /// Takes a claimed business back from its owner (admin only). The owner
  /// loses access at once and the business can be claimed again.
  Future<void> revokeOwnership({
    required String businessId,
    String reason = '',
  }) => _call('revokeOwnership', {
    'businessId': businessId,
    'reason': reason.trim(),
  });

  Future<Map<String, Object?>> _call(
    String name,
    Map<String, Object?> data,
  ) async {
    try {
      final result = await _functions.httpsCallable(name).call(data);
      final value = result.data;
      return value is Map ? Map<String, Object?>.from(value) : const {};
    } on FirebaseFunctionsException catch (error) {
      // The server's messages are written for people, so they can be shown.
      throw StateError(error.message ?? 'Something went wrong. Try again.');
    }
  }
}
