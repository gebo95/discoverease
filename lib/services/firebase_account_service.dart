import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Firebase-backed account operations. Local demo repositories remain separate
/// until account data migration/sync is deliberately enabled.
class FirebaseAccountService {
  FirebaseAccountService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = credential.user;
    if (user != null) await _ensureProfile(user);
    return credential;
  }

  Future<UserCredential> createAccount({
    required String email,
    required String password,
    required String name,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = credential.user;
    if (user == null) throw StateError('Firebase did not return a user.');

    final cleanName = name.trim();
    await user.updateDisplayName(cleanName);
    await _ensureProfile(user, name: cleanName);
    return credential;
  }

  Future<void> _ensureProfile(User user, {String? name}) async {
    final profile = _firestore.collection('users').doc(user.uid);
    final existing = await profile.get();
    if (existing.exists) return;
    final cleanName = name ??
        user.displayName ??
        user.email?.split('@').first ??
        'Traveler';
    await profile.set({
      'id': user.uid,
      'schemaVersion': 1,
      'name': cleanName,
      'homeLocation': '',
      'userType': 'tourist',
      'savedListIds': <String>[],
      'tripIds': <String>[],
    });
  }

  Future<void> signOut() => _auth.signOut();
}
