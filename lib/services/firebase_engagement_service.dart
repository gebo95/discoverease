import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Client actions for business-submitted listings. Aggregates are written only
/// by Cloud Functions; this service never writes business metric documents.
class FirebaseEngagementService {
  FirebaseEngagementService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _functions = functions ?? FirebaseFunctions.instanceFor(region: 'us-central1');

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  Future<HttpsCallableResult<dynamic>> _callActivity(
    String functionName,
    String listingId,
  ) async {
    final callable = _functions.httpsCallable(functionName);
    try {
      return await callable.call({'listingId': listingId});
    } on FirebaseFunctionsException catch (error) {
      final user = _auth.currentUser;
      if (error.code != 'unauthenticated' || user == null) rethrow;

      // The app can still have a cached User while its ID token is stale.
      // Refresh once and retry; the server's receipt key keeps retries safe.
      if (kDebugMode) {
        debugPrint(
          '[DiscoverEase analytics] Refreshing the signed-in user token '
          'after an unauthenticated $functionName response.',
        );
      }
      final tokenResult = await user.getIdTokenResult(true);
      if (kDebugMode) {
        final claims = tokenResult.claims ?? const <String, dynamic>{};
        debugPrint(
          '[DiscoverEase analytics] Auth diagnostic: '
          'appProject=${_auth.app.options.projectId}, '
          'tokenAudience=${claims['aud']}, '
          'tokenIssuer=${claims['iss']}',
        );
      }
      return callable.call({'listingId': listingId});
    }
  }

  Future<bool> isLiked(String listingId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return false;
    final like = await _firestore
        .collection('users')
        .doc(uid)
        .collection('likes')
        .doc(listingId)
        .get();
    return like.exists;
  }

  Future<void> setLiked(String listingId, {required bool liked}) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw StateError('Sign in to like a business experience.');
    final ref = _firestore
        .collection('users')
        .doc(uid)
        .collection('likes')
        .doc(listingId);
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);
      if (liked && !snapshot.exists) {
        transaction.set(ref, {
          'schemaVersion': 1,
          'listingId': listingId,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else if (!liked && snapshot.exists) {
        transaction.delete(ref);
      }
    });
  }

  Future<void> recordView(String listingId) async {
    try {
      final result = await _callActivity('recordListingView', listingId);
      if (kDebugMode) {
        debugPrint('[DiscoverEase analytics] View recorded: ${result.data}');
      }
    } on FirebaseFunctionsException catch (error) {
      if (kDebugMode) {
        debugPrint(
          '[DiscoverEase analytics] View callable failed: '
          '${error.code}: ${error.message}; details=${error.details}',
        );
      }
      rethrow;
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[DiscoverEase analytics] View callable failed: $error');
      }
      rethrow;
    }
  }

  Future<void> recordShare(String listingId) async {
    try {
      final result = await _callActivity('recordListingShare', listingId);
      if (kDebugMode) {
        debugPrint('[DiscoverEase analytics] Share recorded: ${result.data}');
      }
    } on FirebaseFunctionsException catch (error) {
      if (kDebugMode) {
        debugPrint(
          '[DiscoverEase analytics] Share callable failed: '
          '${error.code}: ${error.message}; details=${error.details}',
        );
      }
      rethrow;
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[DiscoverEase analytics] Share callable failed: $error');
      }
      rethrow;
    }
  }

  Future<bool> analyticsAvailable() async {
    try {
      final response = await _functions
          .httpsCallable('checkBusinessAnalyticsReady')
          .call();
      return response.data is Map && response.data['ready'] == true;
    } catch (_) {
      return false;
    }
  }
}
