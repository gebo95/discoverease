import 'dart:async';

import 'package:flutter/foundation.dart';

/// Which experiences currently have paid Featured placement. Featured ones
/// sort first in Discover This Week and Explore and wear a Featured label.
/// A placement that ends while the app is open is dropped on the next check.
class FeaturedRepository extends ChangeNotifier {
  FeaturedRepository({
    Stream<Map<String, DateTime>>? source,
    DateTime Function()? clock,
    Duration tick = const Duration(minutes: 1),
  }) : _clock = clock ?? DateTime.now {
    _subscription = source?.listen(
      setEnds,
      onError: (_) {
        // Featured is an extra. If it cannot load, nothing is featured.
      },
    );
    if (tick > Duration.zero) {
      _timer = Timer.periodic(tick, (_) => _expire());
    }
  }

  final DateTime Function() _clock;
  StreamSubscription<Map<String, DateTime>>? _subscription;
  Timer? _timer;
  Map<String, DateTime> _ends = const {};

  void setEnds(Map<String, DateTime> ends) {
    _ends = Map.of(ends);
    notifyListeners();
  }

  void _expire() {
    final now = _clock();
    final remaining = {
      for (final entry in _ends.entries)
        if (entry.value.isAfter(now)) entry.key: entry.value,
    };
    if (remaining.length != _ends.length) {
      _ends = remaining;
      notifyListeners();
    }
  }

  bool isFeatured(String listingId) {
    final end = _ends[listingId];
    return end != null && end.isAfter(_clock());
  }

  /// The same items with featured ones first; otherwise the order is kept.
  List<T> featuredFirst<T>(List<T> items, String Function(T) idOf) {
    final featured = <T>[];
    final others = <T>[];
    for (final item in items) {
      (isFeatured(idOf(item)) ? featured : others).add(item);
    }
    return [...featured, ...others];
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _timer?.cancel();
    super.dispose();
  }
}
