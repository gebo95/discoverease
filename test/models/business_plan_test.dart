import 'package:flutter_test/flutter_test.dart';

import 'package:discoverease/models/business_plan.dart';

void main() {
  final now = DateTime.utc(2026, 11, 21, 12);

  test('no billing record means Free with 3 Pulses', () {
    expect(BillingSummary.empty.effectivePlan, BusinessPlanId.free);
    expect(BillingSummary.empty.pulsesLeft(now), 3);
  });

  test('a lapsed paid plan counts as Free', () {
    final summary = BillingSummary.fromJson({'plan': 'pro', 'status': 'canceled'});
    expect(summary.effectivePlan, BusinessPlanId.free);
    expect(BillingSummary.fromJson({'plan': 'plus', 'status': 'past_due'}).effectivePlan,
        BusinessPlanId.plus);
  });

  test('usage from an earlier month does not count', () {
    final summary = BillingSummary.fromJson({
      'plan': 'free',
      'pulseMonth': '2026-10',
      'pulsesUsed': 3,
    });
    expect(summary.usedThisMonth(now), 0);
    expect(summary.pulsesLeft(now), 3);
  });

  test('packs are added after the monthly Pulses', () {
    final summary = BillingSummary.fromJson({
      'plan': 'free',
      'pulseMonth': '2026-11',
      'pulsesUsed': 2,
      'packBalance': 5,
    });
    expect(summary.pulsesLeft(now), 6);
  });

  test('Plus has 15 and Pro is unlimited up to the fair-use limit', () {
    expect(BillingSummary.fromJson({'plan': 'plus', 'status': 'active'}).pulsesLeft(now), 15);
    final pro = BillingSummary.fromJson({
      'plan': 'pro',
      'status': 'active',
      'packBalance': 10,
    });
    expect(pro.isUnlimited, isTrue);
    expect(pro.pulsesLeft(now), fairUseMonthlyPulses);
  });

  test('bad numbers in the record are treated as zero', () {
    final summary = BillingSummary.fromJson({
      'plan': 'bogus',
      'pulsesUsed': -4,
      'packBalance': 'x',
    });
    expect(summary.plan, BusinessPlanId.free);
    expect(summary.pulsesUsed, 0);
    expect(summary.packBalance, 0);
  });

  test('product keys match the server names', () {
    expect(BillingProduct.values.map((p) => p.key),
        ['plus', 'pro', 'pack5', 'pack10', 'featured7', 'featured30']);
  });
}
