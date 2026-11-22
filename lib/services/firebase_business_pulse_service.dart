import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../models/business_pulse.dart';

/// Reads the live Pulse posts and lets a business post or end its own.
/// The server checks ownership, the allowed tags and the message text.
class FirebaseBusinessPulseService {
  FirebaseBusinessPulseService({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _functions =
           functions ?? FirebaseFunctions.instanceFor(region: 'us-central1');

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  /// Posts that have not expired. The app filters again as time passes.
  Stream<List<BusinessPulse>> watchActive() => _firestore
      .collection('pulses')
      .where('expiresAt', isGreaterThan: Timestamp.now())
      .limit(300)
      .snapshots()
      .map(
        (snapshot) => [
          for (final doc in snapshot.docs)
            ?BusinessPulse.fromJson(Map<String, Object?>.from(doc.data())),
        ],
      );

  Future<void> post({
    required String uid,
    required String experienceId,
    required String tag,
    required int hours,
    String message = '',
  }) => _call('postPulse', {
    'businessId': uid,
    'experienceId': experienceId,
    'tag': tag,
    'hours': hours,
    'message': message.trim(),
  });

  Future<void> end({required String uid, required String experienceId}) =>
      _call('endPulse', {'businessId': uid, 'experienceId': experienceId});

  Future<void> _call(String name, Map<String, Object?> data) async {
    try {
      await _functions.httpsCallable(name).call(data);
    } on FirebaseFunctionsException catch (error) {
      // The server's messages are written for owners, so they can be shown.
      throw StateError(error.message ?? 'Could not update the Pulse.');
    }
  }
}
