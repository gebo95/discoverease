import 'dart:async';

import 'package:discoverease/models/business_pulse.dart';
import 'package:discoverease/repositories/business_pulse_repository.dart';
import 'package:flutter_test/flutter_test.dart';

BusinessPulse _pulse(
  String id, {
  required DateTime expires,
  String destination = 'nassau',
  DateTime? starts,
}) => BusinessPulse(
  listingId: id,
  businessId: 'biz',
  destinationId: destination,
  title: id,
  tag: 'Live Music',
  startsAt: starts,
  expiresAt: expires,
);

void main() {
  final t0 = DateTime(2026, 11, 21, 18);

  test('only posts that are still showing are kept', () {
    final repository = BusinessPulseRepository(clock: () => t0, tick: Duration.zero);
    repository.setPulses([
      _pulse('a', expires: t0.add(const Duration(hours: 1))),
      _pulse('b', expires: t0.subtract(const Duration(minutes: 1))),
    ]);
    expect(repository.forListing('a'), isNotNull);
    expect(repository.forListing('b'), isNull);
    expect(repository.forListing('missing'), isNull);
    repository.dispose();
  });

  test('a post disappears once its time passes', () {
    var now = t0;
    final repository = BusinessPulseRepository(clock: () => now, tick: Duration.zero);
    repository.setPulses([_pulse('a', expires: t0.add(const Duration(hours: 1)))]);
    expect(repository.forListing('a'), isNotNull);
    now = t0.add(const Duration(hours: 2));
    expect(repository.forListing('a'), isNull);
    expect(repository.forDestination('nassau'), isEmpty);
    repository.dispose();
  });

  test('a destination lists its own posts, newest first', () {
    final repository = BusinessPulseRepository(clock: () => t0, tick: Duration.zero);
    final later = t0.add(const Duration(hours: 5));
    repository.setPulses([
      _pulse('old', expires: later, starts: t0.subtract(const Duration(hours: 2))),
      _pulse('new', expires: later, starts: t0.subtract(const Duration(minutes: 5))),
      _pulse('elsewhere', expires: later, destination: 'paris', starts: t0),
    ]);
    expect(repository.forDestination('nassau').map((p) => p.listingId), ['new', 'old']);
    expect(repository.forDestination('paris').single.listingId, 'elsewhere');
    expect(repository.forDestination('rome'), isEmpty);
    repository.dispose();
  });

  test('follows a stream and tells listeners when it changes', () async {
    final controller = StreamController<List<BusinessPulse>>();
    final repository = BusinessPulseRepository(
      source: controller.stream,
      clock: () => t0,
      tick: Duration.zero,
    );
    var notified = 0;
    repository.addListener(() => notified++);
    controller.add([_pulse('a', expires: t0.add(const Duration(hours: 1)))]);
    await Future<void>.delayed(Duration.zero);
    expect(repository.forListing('a'), isNotNull);
    expect(notified, 1);
    controller.add(const []);
    await Future<void>.delayed(Duration.zero);
    expect(repository.forListing('a'), isNull);
    await controller.close();
    repository.dispose();
  });

  test('a stream error leaves the cards without a post instead of crashing', () async {
    final controller = StreamController<List<BusinessPulse>>();
    final repository = BusinessPulseRepository(
      source: controller.stream,
      clock: () => t0,
      tick: Duration.zero,
    );
    controller.addError(StateError('permission denied'));
    await Future<void>.delayed(Duration.zero);
    expect(repository.forListing('a'), isNull);
    await controller.close();
    repository.dispose();
  });

  test('a post counts as seen once opened, and a newer post from the same place does not', () {
    final repository = BusinessPulseRepository(clock: () => t0, tick: Duration.zero);
    final first = _pulse('a', expires: t0.add(const Duration(hours: 3)), starts: t0);
    final second = _pulse('a', expires: t0.add(const Duration(hours: 3)), starts: t0.add(const Duration(minutes: 1)));
    var notified = 0;
    repository.addListener(() => notified++);
    expect(repository.isSeen(first), isFalse);
    repository.markSeen(first);
    repository.markSeen(first);
    expect(repository.isSeen(first), isTrue);
    expect(notified, 1);
    expect(repository.isSeen(second), isFalse);
    repository.dispose();
  });
}
