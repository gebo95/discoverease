import 'dart:math';

/// The order Explore shows results in, so no business is stuck at the bottom.
///
/// * Everything is shuffled, but the same [seed] always gives the same order,
///   so results stay put while scrolling, filtering or coming back. Use a new
///   seed for each visit to Explore.
/// * A listing with a live Pulse gets a slight boost toward the top.
/// * Paid (Featured) listings are not pinned first: each lands at a random
///   spot among the first [paidWindow] results.
///
/// Filters and search are applied before this, so it only reorders what the
/// traveler already asked for.
List<T> exploreOrder<T>(
  List<T> items, {
  required String Function(T) idOf,
  required int seed,
  bool Function(T)? isPaid,
  bool Function(T)? hasPulse,
  int paidWindow = 10,
}) {
  double roll(String id, String salt) => Random(Object.hash(seed, id, salt)).nextDouble();

  final paid = <T>[];
  final rest = <T>[];
  for (final item in items) {
    (isPaid?.call(item) == true ? paid : rest).add(item);
  }

  double key(T item) =>
      roll(idOf(item), 'order') * (hasPulse?.call(item) == true ? 0.6 : 1.0);

  final ordered = [...rest]..sort((a, b) => key(a).compareTo(key(b)));
  paid.sort((a, b) => key(a).compareTo(key(b)));
  final window = max(1, min(paidWindow, items.length));
  for (final item in paid) {
    final spot = Random(Object.hash(seed, idOf(item), 'spot')).nextInt(window);
    ordered.insert(min(spot, ordered.length), item);
  }
  return ordered;
}
