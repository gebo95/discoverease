import 'package:discoverease/models/business_pulse.dart';
import 'package:discoverease/repositories/business_pulse_repository.dart';
import 'package:discoverease/shared/components/badges/de_pulse_badge.dart';
import 'package:discoverease/shared/components/badges/de_pulse_line.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

BusinessPulse _pulse({String message = 'Band starts at 8'}) => BusinessPulse(
  listingId: 'x1',
  businessId: 'b',
  destinationId: 'nassau',
  title: 'Bar',
  tag: 'Live Music',
  message: message,
  startsAt: DateTime.now(),
  expiresAt: DateTime.now().add(const Duration(hours: 3)),
);

Future<BusinessPulseRepository?> _show(
  WidgetTester tester, {
  BusinessPulse? pulse,
  String? fallback,
  bool provide = true,
}) async {
  BusinessPulseRepository? repository;
  Widget line = DEPulseLine(listingId: 'x1', fallbackText: fallback);
  if (provide) {
    repository = BusinessPulseRepository(tick: Duration.zero);
    addTearDown(repository.dispose);
    if (pulse != null) repository.setPulses([pulse]);
    line = ChangeNotifierProvider<BusinessPulseRepository>.value(value: repository, child: line);
  }
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: line)));
  await tester.pump();
  return repository;
}

void main() {
  testWidgets('a live Pulse shows its tag and message', (tester) async {
    await _show(tester, pulse: _pulse(), fallback: 'DJ starts at 10 PM');
    expect(find.text('Live Music'), findsOneWidget);
    expect(find.text('Band starts at 8'), findsOneWidget);
    expect(find.textContaining('DJ starts'), findsNothing);
  });

  testWidgets('without a message it says how long the Pulse lasts', (tester) async {
    await _show(tester, pulse: _pulse(message: ''));
    expect(find.textContaining('Until'), findsOneWidget);
  });

  testWidgets('it flashes until seen, then holds still', (tester) async {
    final pulse = _pulse();
    final repository = await _show(tester, pulse: pulse);
    DEPulseBadge badge() => tester.widget<DEPulseBadge>(find.byType(DEPulseBadge));
    expect(badge().animate, isTrue);
    repository!.markSeen(pulse);
    await tester.pump();
    expect(badge().animate, isFalse);
  });

  testWidgets('without a live Pulse the listing\'s own update shows', (tester) async {
    await _show(tester, fallback: 'DJ starts at 10 PM');
    expect(find.text('🔴 DJ starts at 10 PM'), findsOneWidget);
    expect(find.byType(DEPulseBadge), findsNothing);
  });

  testWidgets('with nothing to show it takes no space and works without Pulse set up', (tester) async {
    await _show(tester);
    expect(find.byType(DEPulseBadge), findsNothing);
    await _show(tester, provide: false, fallback: '');
    expect(find.byType(Text), findsNothing);
  });
}
