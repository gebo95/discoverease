import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:discoverease/features/business/pages/admin_plans_page.dart';
import 'package:discoverease/features/business/pages/plans_page.dart';
import 'package:discoverease/models/business_plan.dart';
import 'package:discoverease/services/firebase_billing_service.dart';

class _FakeBilling implements FirebaseBillingService {
  _FakeBilling(this.summary);
  final BillingSummary summary;
  final requested = <String>[];

  @override
  Stream<BillingSummary> watch(String uid) => Stream.value(summary);

  @override
  Future<Uri> checkoutUrl({
    required String uid,
    required BillingProduct product,
    String? experienceId,
  }) async {
    requested.add('${product.key}:${experienceId ?? ''}');
    return Uri.parse('https://checkout.example/${product.key}');
  }

  @override
  Future<String> grantPlan({
    String? email,
    String? businessId,
    required BusinessPlanId plan,
    required int months,
  }) async {
    requested.add('grant:${email ?? businessId}:${plan.name}:$months');
    return 'Cafe has ${planInfo(plan).label}.';
  }

  @override
  Future<Uri> portalUrl(String uid) async {
    requested.add('portal');
    return Uri.parse('https://billing.example/portal');
  }
}

Future<List<Uri>> _show(WidgetTester tester, _FakeBilling billing) async {
  tester.view.physicalSize = const Size(420, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final opened = <Uri>[];
  await tester.pumpWidget(
    Provider<FirebaseBillingService>.value(
      value: billing,
      child: MaterialApp(
        home: PlansPage(
          uid: 'biz-1',
          openLink: (uri) async {
            opened.add(uri);
            return true;
          },
        ),
      ),
    ),
  );
  await tester.pump();
  return opened;
}

void main() {
  testWidgets('a Free business sees its Pulses left and can pick a plan', (tester) async {
    final billing = _FakeBilling(BillingSummary.empty);
    final opened = await _show(tester, billing);
    expect(find.textContaining('Free plan'), findsOneWidget);
    expect(find.textContaining('3 Pulses left'), findsOneWidget);
    await tester.tap(find.text('Choose Plus'));
    await tester.pump();
    expect(billing.requested, ['plus:']);
    expect(opened.single.toString(), 'https://checkout.example/plus');
  });

  testWidgets('a business that already has a plan changes it in billing', (tester) async {
    final billing = _FakeBilling(
      BillingSummary.fromJson({'plan': 'plus', 'status': 'active'}),
    );
    final opened = await _show(tester, billing);
    expect(find.text('Your plan'), findsOneWidget);
    await tester.tap(find.text('Change in billing').first);
    await tester.pump();
    expect(billing.requested, ['portal']);
    expect(opened.single.toString(), 'https://billing.example/portal');
  });

  testWidgets('Pulse packs open checkout for the right size', (tester) async {
    final billing = _FakeBilling(BillingSummary.empty);
    await _show(tester, billing);
    await tester.tap(find.text('Add 15 Pulses'));
    await tester.pump();
    expect(billing.requested, ['pack15:']);
  });

  testWidgets('bought packs show in the summary', (tester) async {
    final billing = _FakeBilling(BillingSummary.fromJson({'packBalance': 5}));
    await _show(tester, billing);
    expect(find.textContaining('8 Pulses left'), findsOneWidget);
    expect(find.textContaining('5 from packs'), findsOneWidget);
  });

  testWidgets('a granted plan shows its end date and still lets the business subscribe', (tester) async {
    final billing = _FakeBilling(
      BillingSummary(
        compPlan: BusinessPlanId.plus,
        compUntil: DateTime.now().add(const Duration(days: 30)),
      ),
    );
    final opened = await _show(tester, billing);
    expect(find.textContaining('Plus plan'), findsOneWidget);
    expect(find.textContaining('15 Pulses left'), findsOneWidget);
    expect(find.textContaining('Free until'), findsOneWidget);
    // Not paying yet, so choosing Pro goes to checkout, not the billing page.
    await tester.tap(find.text('Choose Pro'));
    await tester.pump();
    expect(billing.requested, ['pro:']);
    expect(opened.single.toString(), 'https://checkout.example/pro');
  });

  testWidgets('an expired grant no longer counts', (tester) async {
    final billing = _FakeBilling(
      BillingSummary(
        compPlan: BusinessPlanId.pro,
        compUntil: DateTime.now().subtract(const Duration(days: 1)),
      ),
    );
    await _show(tester, billing);
    expect(find.textContaining('Free plan'), findsOneWidget);
  });

  testWidgets('an admin can give a plan by email', (tester) async {
    final billing = _FakeBilling(BillingSummary.empty);
    tester.view.physicalSize = const Size(420, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      Provider<FirebaseBillingService>.value(
        value: billing,
        child: const MaterialApp(home: AdminPlansPage()),
      ),
    );
    await tester.tap(find.text('Give plan'));
    await tester.pump();
    expect(find.text('Enter the business email.'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'cafe@example.com');
    await tester.tap(find.text('Give plan'));
    await tester.pump();
    expect(billing.requested, ['grant:cafe@example.com:plus:6']);
    expect(find.text('Cafe has Plus.'), findsOneWidget);
    await tester.tap(find.text('Remove granted plan'));
    await tester.pump();
    expect(billing.requested.last, 'grant:cafe@example.com:free:0');
  });

  testWidgets('Pro shows unlimited instead of a countdown', (tester) async {
    final billing = _FakeBilling(
      BillingSummary.fromJson({
        'plan': 'pro',
        'status': 'active',
        'pulseMonth': BillingSummary.monthKey(DateTime.now()),
        'pulsesUsed': 2,
      }),
    );
    await _show(tester, billing);
    expect(find.textContaining('Unlimited Pulses'), findsWidgets);
    expect(find.textContaining('298'), findsNothing);
    expect(find.textContaining('Fair use'), findsOneWidget);
  });
}
