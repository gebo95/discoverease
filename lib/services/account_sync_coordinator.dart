import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../repositories/saved_repository.dart';
import '../repositories/trip_repository.dart';
import 'firebase_account_service.dart';
import 'firebase_user_data_store.dart';

enum AccountSyncState { guest, loading, synced, syncing, error }

/// Keeps local repositories aligned with the active Firebase account.
/// Guest mode continues to use the app's existing demo data.
class AccountSyncCoordinator extends ChangeNotifier {
  AccountSyncCoordinator({
    required this._accounts,
    required this._store,
    required this._trips,
    required this._saved,
  });

  final FirebaseAccountService _accounts;
  final FirebaseUserDataStore _store;
  final TripRepository _trips;
  final SavedRepository _saved;
  StreamSubscription<User?>? _authSubscription;
  Timer? _debounce;
  String? _uid;
  int _authGeneration = 0;
  bool _syncing = false;
  bool _dirty = false;
  bool _started = false;
  AccountSyncState _state = AccountSyncState.guest;
  String? _errorMessage;

  AccountSyncState get state => _state;
  String? get errorMessage => _errorMessage;

  void start() {
    if (_started) return;
    _started = true;
    _trips.addListener(_onRepositoryChanged);
    _saved.addListener(_onRepositoryChanged);
    _authSubscription = _accounts.authStateChanges.listen(
      _onAuthChanged,
      onError: (Object error) => _setError('Could not check account status.'),
    );
  }

  Future<void> retry() async {
    final user = _accounts.currentUser;
    if (user == null) return;
    if (_state == AccountSyncState.error && _uid == null) {
      await _onAuthChanged(user);
    } else {
      _queueSync();
    }
  }

  Future<void> _onAuthChanged(User? user) async {
    final generation = ++_authGeneration;
    _debounce?.cancel();
    _uid = null;
    _dirty = false;
    if (user == null) {
      _state = AccountSyncState.guest;
      _errorMessage = null;
      _trips.loadDemoData();
      _saved.loadDemoData();
      notifyListeners();
      return;
    }

    _state = AccountSyncState.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      final data = await _store.load(user.uid);
      if (generation != _authGeneration) return;
      _trips.loadAccountData(
        current: data.currentTrip,
        upcoming: data.upcomingTrips,
      );
      _saved.loadAccountData(data.savedExperiences);
      _uid = user.uid;
      _state = AccountSyncState.synced;
      _errorMessage = null;
      notifyListeners();
    } catch (_) {
      if (generation != _authGeneration) return;
      // Never expose the previous guest/account data after a failed account load.
      _trips.loadAccountData(current: null, upcoming: const []);
      _saved.loadAccountData(const []);
      _state = AccountSyncState.error;
      _errorMessage = 'Could not load your cloud trips and saves. Check your '
          'connection and Firestore rules, then tap Retry.';
      notifyListeners();
    }
  }

  void _onRepositoryChanged() {
    if (_uid == null || _state != AccountSyncState.synced) return;
    _queueSync();
  }

  void _queueSync() {
    if (_uid == null) return;
    _dirty = true;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), () {
      if (!_syncing) unawaited(_flush());
    });
  }

  Future<void> _flush() async {
    final uid = _uid;
    if (uid == null || _syncing || !_dirty) return;
    _syncing = true;
    _dirty = false;
    _state = AccountSyncState.syncing;
    _errorMessage = null;
    notifyListeners();
    try {
      await _store.replaceTrips(
        uid,
        current: _trips.hasCurrentTrip ? _trips.getCurrentTrip() : null,
        upcoming: _trips.getUpcomingTrips(),
      );
      await _store.replaceSaved(uid, _saved.getAllSaved());
      if (_uid == uid) {
        _state = AccountSyncState.synced;
        _errorMessage = null;
      }
    } catch (_) {
      if (_uid == uid) {
        _state = AccountSyncState.error;
        _errorMessage = 'Your changes could not be synced. Tap Retry to try '
            'again when you are online.';
      }
    } finally {
      _syncing = false;
      notifyListeners();
      if (_dirty && _uid != null) _queueSync();
    }
  }

  void _setError(String message) {
    _state = AccountSyncState.error;
    _errorMessage = message;
    notifyListeners();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _authSubscription?.cancel();
    _trips.removeListener(_onRepositoryChanged);
    _saved.removeListener(_onRepositoryChanged);
    super.dispose();
  }
}
