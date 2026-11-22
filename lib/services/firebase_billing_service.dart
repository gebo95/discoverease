import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../models/business_plan.dart';

/// Reads a business's plan and starts purchases. Money is handled by Stripe:
/// the app only asks the server for a checkout or billing link and opens it.
/// Plans, packs and Featured placement change only after Stripe confirms.
class FirebaseBillingService {
  FirebaseBillingService({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _functions =
           functions ?? FirebaseFunctions.instanceFor(region: 'us-central1');

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  Stream<BillingSummary> watch(String uid) => _firestore
      .collection('subscriptions')
      .doc(uid)
      .snapshots()
      .map(
        (doc) => doc.exists
            ? BillingSummary.fromJson(Map<String, Object?>.from(doc.data()!))
            : BillingSummary.empty,
      );

  /// A Stripe Checkout address for [product]. Featured needs the experience.
  Future<Uri> checkoutUrl({
    required String uid,
    required BillingProduct product,
    String? experienceId,
  }) => _url('createCheckoutSession', {
    'businessId': uid,
    'product': product.key,
    'experienceId': ?experienceId,
  });

  /// Stripe's page for changing or cancelling a plan and viewing receipts.
  Future<Uri> portalUrl(String uid) =>
      _url('createPortalSession', {'businessId': uid});

  Future<Uri> _url(String name, Map<String, Object?> data) async {
    try {
      final result = await _functions.httpsCallable(name).call(data);
      final url = (result.data as Map)['url'] as String?;
      final uri = url == null ? null : Uri.tryParse(url);
      if (uri == null || uri.scheme != 'https') {
        throw StateError('Could not open billing. Try again.');
      }
      return uri;
    } on FirebaseFunctionsException catch (error) {
      throw StateError(error.message ?? 'Could not open billing.');
    }
  }
}

/// The experiences with paid Featured placement, for sorting and labels.
class FeaturedSource {
  FeaturedSource({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;
  final FirebaseFirestore _firestore;

  Stream<Map<String, DateTime>> watch() => _firestore
      .collection('featured')
      .where('endsAt', isGreaterThan: Timestamp.now())
      .limit(200)
      .snapshots()
      .map((snapshot) {
        final ends = <String, DateTime>{};
        for (final doc in snapshot.docs) {
          final end = doc.data()['endsAt'];
          if (end is Timestamp) ends[doc.id] = end.toDate();
        }
        return ends;
      });
}
