import 'package:discoverease/mock_data/listings/live_now.dart';
import 'package:discoverease/models/business_pulse.dart';
import 'package:discoverease/repositories/business_pulse_repository.dart';
import 'package:discoverease/shared/components/badges/de_pulse_badge.dart';
import 'package:discoverease/shared/components/cards/de_experience_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

Widget _card(BusinessPulseRepository? repository) {
  final card = SizedBox(
    height: 340,
    child: ListView(
      scrollDirection: Axis.horizontal,
      children: [DEExperienceCard(listing: liveNowListings.first)],
    ),
  );
  return MaterialApp(
    home: Scaffold(
      body: repository == null
          ? card
          : ChangeNotifierProvider<BusinessPulseRepository>.value(
              value: repository,
              child: card,
            ),
    ),
  );
}

void main() {
  testWidgets('the badge shows what is happening', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: DEPulseBadge(label: 'Live Music'))),
    );
    expect(find.text('Live Music'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('the dot holds still when the device asks for reduced motion', (tester) async {
    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(disableAnimations: true),
        child: MaterialApp(home: Scaffold(body: DEPulseBadge(label: 'Live Music'))),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Live Music'), findsOneWidget);
  });

  testWidgets('a card with a live Pulse shows its tag', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = BusinessPulseRepository(tick: Duration.zero);
    addTearDown(repository.dispose);
    repository.setPulses([
      BusinessPulse(
        listingId: liveNowListings.first.id,
        businessId: 'b',
        destinationId: liveNowListings.first.destinationId,
        title: 'T',
        tag: 'Happy Hour',
        expiresAt: DateTime.now().add(const Duration(hours: 2)),
      ),
    ]);
    await tester.pumpWidget(_card(repository));
    await tester.pump();
    expect(find.text('Happy Hour'), findsOneWidget);
  });

  testWidgets('a card without one, or without Pulse set up, shows no badge', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(_card(null));
    await tester.pump();
    expect(find.byType(DEPulseBadge), findsNothing);

    final empty = BusinessPulseRepository(tick: Duration.zero);
    addTearDown(empty.dispose);
    await tester.pumpWidget(_card(empty));
    await tester.pump();
    expect(find.byType(DEPulseBadge), findsNothing);
  });
}
