import 'package:discoverease/models/business_pulse.dart';
import 'package:flutter_test/flutter_test.dart';

BusinessPulse _pulse({DateTime? expires, DateTime? starts, String message = ''}) =>
    BusinessPulse(
      listingId: 'exp-1',
      businessId: 'biz-1',
      destinationId: 'nassau',
      title: 'Sunset Bar',
      tag: 'Live Music',
      message: message,
      startsAt: starts,
      expiresAt: expires ?? DateTime(2026, 11, 21, 21, 30),
    );

void main() {
  group('reading a post', () {
    test('needs a listing, a tag and an expiry', () {
      final good = BusinessPulse.fromJson({
        'listingId': 'exp-1',
        'tag': 'Happy Hour',
        'message': 'Half price',
        'title': 'Bar',
        'destinationId': 'nassau',
        'expiresAt': DateTime(2026, 11, 21, 22),
      });
      expect(good!.tag, 'Happy Hour');
      expect(good.message, 'Half price');
      expect(BusinessPulse.fromJson({'tag': 'x', 'expiresAt': DateTime(2026)}), isNull);
      expect(BusinessPulse.fromJson({'listingId': 'a', 'expiresAt': DateTime(2026)}), isNull);
      expect(BusinessPulse.fromJson({'listingId': 'a', 'tag': 'x'}), isNull);
    });

    test('ignores values of the wrong type', () {
      final pulse = BusinessPulse.fromJson({
        'listingId': 'a',
        'tag': 'x',
        'message': 5,
        'expiresAt': DateTime(2026),
      });
      expect(pulse!.message, '');
    });
  });

  test('a post is active until it expires', () {
    final pulse = _pulse(expires: DateTime(2026, 11, 21, 21));
    expect(pulse.isActive(DateTime(2026, 11, 21, 20, 59)), isTrue);
    expect(pulse.isActive(DateTime(2026, 11, 21, 21)), isFalse);
  });

  test('until label says the time today and the weekday later', () {
    final now = DateTime(2026, 11, 21, 18);
    expect(_pulse(expires: DateTime(2026, 11, 21, 21, 30)).untilLabel(now), 'Until 9:30 PM');
    expect(_pulse(expires: DateTime(2026, 11, 22, 0, 5)).untilLabel(now), 'Until Sun 12:05 AM');
  });

  test('a new post gets a new key so it is shown again', () {
    final first = _pulse(starts: DateTime(2026, 11, 21, 18));
    final second = _pulse(starts: DateTime(2026, 11, 21, 19));
    expect(first.postKey, isNot(second.postKey));
    expect(first.postKey, first.postKey);
  });

  test('choices are in step with the server lists', () {
    expect(businessPulseTags.toSet().length, businessPulseTags.length);
    expect(businessPulseHours, [3, 6, 12, 24, 72, 168]);
    expect(pulseDurationLabel(3), '3 hours');
    expect(pulseDurationLabel(24), '1 day');
    expect(pulseDurationLabel(72), '3 days');
  });
}
