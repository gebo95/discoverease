import 'package:flutter_test/flutter_test.dart';

import 'package:discoverease/repositories/featured_repository.dart';

void main() {
  var clock = DateTime.utc(2026, 11, 21, 12);

  FeaturedRepository build(Map<String, DateTime> ends) {
    final repo = FeaturedRepository(clock: () => clock, tick: Duration.zero);
    addTearDown(repo.dispose);
    repo.setEnds(ends);
    return repo;
  }

  test('only placements that have not ended are featured', () {
    final repo = build({
      'a': DateTime.utc(2026, 11, 25),
      'b': DateTime.utc(2026, 11, 1),
    });
    expect(repo.isFeatured('a'), isTrue);
    expect(repo.isFeatured('b'), isFalse);
    expect(repo.isFeatured('c'), isFalse);
  });

  test('featured items come first and the rest keep their order', () {
    final repo = build({'c': DateTime.utc(2026, 12, 1), 'd': DateTime.utc(2026, 12, 1)});
    expect(
      repo.featuredFirst(['a', 'b', 'c', 'd', 'e'], (id) => id),
      ['c', 'd', 'a', 'b', 'e'],
    );
  });

  test('a placement stops counting once its end time passes', () {
    clock = DateTime.utc(2026, 11, 21, 12);
    final repo = build({'a': DateTime.utc(2026, 11, 21, 13)});
    expect(repo.isFeatured('a'), isTrue);
    clock = DateTime.utc(2026, 11, 21, 13, 1);
    expect(repo.isFeatured('a'), isFalse);
  });
}
