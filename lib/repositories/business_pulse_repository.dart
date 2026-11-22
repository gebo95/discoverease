import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/business_pulse.dart';

/// The Pulse posts that are showing right now, for cards, listing pages and
/// the Happening now section. Fed by a stream of every post that had not
/// expired when it was loaded; posts that expire while the app is open are
/// dropped by a minute-by-minute check, so a card never shows a stale one.
class BusinessPulseRepository extends ChangeNotifier {
  BusinessPulseRepository({
    Stream<List<BusinessPulse>>? source,
    DateTime Function()? clock,
    Duration tick = const Duration(minutes: 1),
  }) : _clock = clock ?? DateTime.now {
    _subscription = source?.listen(
      setPulses,
      onError: (_) {
        // Pulse is a nice extra. If it cannot load, cards simply show none.
      },
    );
    if (tick > Duration.zero) {
      _timer = Timer.periodic(tick, (_) => _expire());
    }
  }

  final DateTime Function() _clock;
  StreamSubscription<List<BusinessPulse>>? _subscription;
  Timer? _timer;
  Map<String, BusinessPulse> _byListing = const {};
  final Set<String> _seen = {};

  void setPulses(List<BusinessPulse> pulses) {
    final now = _clock();
    _byListing = {
      for (final pulse in pulses)
        if (pulse.isActive(now)) pulse.listingId: pulse,
    };
    notifyListeners();
  }

  void _expire() {
    final now = _clock();
    final remaining = {
      for (final entry in _byListing.entries)
        if (entry.value.isActive(now)) entry.key: entry.value,
    };
    if (remaining.length != _byListing.length) {
      _byListing = remaining;
      notifyListeners();
    }
  }

  /// Whether the traveler has already opened this exact post. A new post from
  /// the same business has a new key, so it counts as unseen again. Held for
  /// the current app session.
  bool isSeen(BusinessPulse pulse) => _seen.contains(pulse.postKey);

  void markSeen(BusinessPulse pulse) {
    if (_seen.add(pulse.postKey)) notifyListeners();
  }

  /// The listing's Pulse, or null when it has none showing.
  BusinessPulse? forListing(String listingId) {
    final pulse = _byListing[listingId];
    return pulse != null && pulse.isActive(_clock()) ? pulse : null;
  }

  /// Everything showing in [destinationId], newest first.
  List<BusinessPulse> forDestination(String destinationId) {
    final now = _clock();
    final list = [
      for (final pulse in _byListing.values)
        if (pulse.destinationId == destinationId && pulse.isActive(now)) pulse,
    ]..sort((a, b) {
        final left = a.startsAt ?? a.expiresAt;
        final right = b.startsAt ?? b.expiresAt;
        return right.compareTo(left);
      });
    return list;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _timer?.cancel();
    super.dispose();
  }
}
