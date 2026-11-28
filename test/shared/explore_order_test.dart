import 'package:flutter_test/flutter_test.dart';

import 'package:discoverease/shared/utils/explore_order.dart';

List<String> _ids(int n) => [for (var i = 0; i < n; i++) 'item-$i'];

void main() {
  test('everything is kept, nothing is added or lost', () {
    final items = _ids(30);
    final result = exploreOrder<String>(
      items,
      idOf: (id) => id,
      seed: 7,
      isPaid: (id) => id == 'item-3' || id == 'item-20',
    );
    expect(result.length, items.length);
    expect(result.toSet(), items.toSet());
  });

  test('the same seed gives the same order, and the order does not depend on input order', () {
    final items = _ids(25);
    final a = exploreOrder<String>(items, idOf: (id) => id, seed: 11);
    final b = exploreOrder<String>(items, idOf: (id) => id, seed: 11);
    expect(a, b);
    final c = exploreOrder<String>(items.reversed.toList(), idOf: (id) => id, seed: 11);
    expect(c, a);
  });

  test('a new seed gives a different order', () {
    final items = _ids(25);
    expect(
      exploreOrder<String>(items, idOf: (id) => id, seed: 1),
      isNot(exploreOrder<String>(items, idOf: (id) => id, seed: 2)),
    );
  });

  test('paid listings land near the top but are not always first', () {
    final items = _ids(60);
    final positions = <int>[];
    for (var seed = 0; seed < 200; seed++) {
      final result = exploreOrder<String>(
        items,
        idOf: (id) => id,
        seed: seed,
        isPaid: (id) => id == 'item-40',
      );
      positions.add(result.indexOf('item-40'));
    }
    expect(positions.every((p) => p < 10), isTrue);
    expect(positions.toSet().length, greaterThan(3));
    expect(positions.where((p) => p == 0).length, lessThan(100));
  });

  test('several paid listings all stay within the first 15', () {
    final items = _ids(60);
    final paid = {'item-30', 'item-31', 'item-32', 'item-33'};
    for (var seed = 0; seed < 100; seed++) {
      final result = exploreOrder<String>(
        items,
        idOf: (id) => id,
        seed: seed,
        isPaid: paid.contains,
      );
      for (final id in paid) {
        expect(result.indexOf(id), lessThan(15));
      }
    }
  });

  test('a live Pulse gives a slight boost on average', () {
    final items = _ids(40);
    var withPulse = 0;
    var without = 0;
    const runs = 300;
    for (var seed = 0; seed < runs; seed++) {
      final result = exploreOrder<String>(
        items,
        idOf: (id) => id,
        seed: seed,
        hasPulse: (id) => id == 'item-5',
      );
      withPulse += result.indexOf('item-5');
      without += result.indexOf('item-6');
    }
    expect(withPulse, lessThan(without));
  });

  test('a short list with paid items still works', () {
    final result = exploreOrder<String>(
      ['a', 'b'],
      idOf: (id) => id,
      seed: 3,
      isPaid: (id) => id == 'a',
    );
    expect(result.toSet(), {'a', 'b'});
    expect(exploreOrder<String>([], idOf: (id) => id, seed: 1), isEmpty);
  });
}
