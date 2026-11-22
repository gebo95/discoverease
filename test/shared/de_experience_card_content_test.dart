import 'package:discoverease/models/business_pulse.dart';
import 'package:discoverease/models/listing.dart';
import 'package:discoverease/repositories/business_pulse_repository.dart';
import 'package:discoverease/repositories/saved_repository.dart';
import 'package:discoverease/shared/components/badges/de_pulse_badge.dart';
import 'package:discoverease/shared/components/cards/de_experience_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

Listing _listing({
  Object? rating,
  String category = 'Tours',
  String subcategory = 'Boat Tour',
  String status = 'New',
}) => Listing.fromCatalogJson({
  'id': 'zz-card',
  'title': 'Sunset Cruise',
  'subtitle': 'Island Tours',
  'category': category,
  'subcategory': subcategory,
  'destinationId': 'nassau',
  'destination': 'Nassau',
  'location': 'Paradise Island',
  'imageUrl': '',
  'price': r'$$',
  'rating': rating,
  'status': status,
});

Future<void> _show(
  WidgetTester tester,
  Widget card, {
  BusinessPulseRepository? pulses,
}) async {
  tester.view.physicalSize = const Size(360, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final body = SizedBox(height: 340, child: ListView(scrollDirection: Axis.horizontal, children: [card]));
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: pulses == null
            ? body
            : ChangeNotifierProvider<BusinessPulseRepository>.value(value: pulses, child: body),
      ),
    ),
  );
  await tester.pump();
}

BusinessPulse _pulse() => BusinessPulse(
  listingId: 'zz-card',
  businessId: 'b',
  destinationId: 'nassau',
  title: 'Sunset Cruise',
  tag: 'Happy Hour',
  startsAt: DateTime.now(),
  expiresAt: DateTime.now().add(const Duration(hours: 2)),
);

void main() {
  testWidgets('no heart until the place is saved', (tester) async {
    await _show(tester, DEExperienceCard(listing: _listing()));
    expect(find.byIcon(Icons.favorite_rounded), findsNothing);
    expect(find.byIcon(Icons.favorite_border_rounded), findsNothing);
    await _show(tester, DEExperienceCard(listing: _listing(), isSaved: true));
    expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
  });

  testWidgets('no rating text until there is a rating', (tester) async {
    await _show(tester, DEExperienceCard(listing: _listing()));
    expect(find.byIcon(Icons.star_rounded), findsNothing);
    // The "New" tag above the title stays; the rating slot adds no second one.
    expect(find.text('New'), findsOneWidget);
    await _show(tester, DEExperienceCard(listing: _listing(rating: 4.6)));
    expect(find.byIcon(Icons.star_rounded), findsOneWidget);
    expect(find.text('4.6'), findsOneWidget);
  });

  testWidgets('a row already named after the category does not repeat it', (tester) async {
    await _show(tester, DEExperienceCard(listing: _listing(subcategory: ''), sectionCategory: 'Tours'));
    expect(find.text('Tours'), findsNothing);
    await _show(tester, DEExperienceCard(listing: _listing(subcategory: ''), sectionCategory: 'Dining'));
    expect(find.text('Tours'), findsOneWidget);
  });

  testWidgets('several labels switch one after another', (tester) async {
    await _show(tester, DEExperienceCard(listing: _listing(subcategory: 'Boat Tour, Beach')));
    expect(find.text('Tours'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Boat Tour'), findsOneWidget);
  });

  testWidgets('a live Pulse takes the spot above the title from the status tag', (tester) async {
    final pulses = BusinessPulseRepository(tick: Duration.zero)..setPulses([_pulse()]);
    addTearDown(pulses.dispose);
    await _show(tester, DEExperienceCard(listing: _listing()), pulses: pulses);
    expect(find.text('Happy Hour'), findsOneWidget);
    expect(find.text('New'), findsNothing);
  });

  testWidgets('the Pulse dot flashes until it is seen, then holds still', (tester) async {
    final pulse = _pulse();
    final pulses = BusinessPulseRepository(tick: Duration.zero)..setPulses([pulse]);
    addTearDown(pulses.dispose);
    await _show(tester, DEExperienceCard(listing: _listing()), pulses: pulses);
    DEPulseBadge badge() => tester.widget<DEPulseBadge>(find.byType(DEPulseBadge));
    expect(badge().animate, isTrue);
    pulses.markSeen(pulse);
    await tester.pump();
    expect(badge().animate, isFalse);

    // A newer post from the same business flashes again.
    final newer = BusinessPulse(
      listingId: pulse.listingId,
      businessId: pulse.businessId,
      destinationId: pulse.destinationId,
      title: pulse.title,
      tag: 'Live Music',
      startsAt: pulse.startsAt!.add(const Duration(minutes: 5)),
      expiresAt: pulse.expiresAt,
    );
    pulses.setPulses([newer]);
    await tester.pump();
    expect(badge().animate, isTrue);
  });

  testWidgets('double tap saves the place and shows the heart; again removes it', (tester) async {
    final saved = SavedRepository();
    addTearDown(saved.dispose);
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider<SavedRepository>.value(
            value: saved,
            child: SizedBox(
              height: 340,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [DEExperienceCard(listing: _listing())],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.byIcon(Icons.favorite_rounded), findsNothing);

    Future<void> doubleTap() async {
      final target = find.byType(DEExperienceCard);
      await tester.tap(target);
      await tester.pump(const Duration(milliseconds: 60));
      await tester.tap(target);
      await tester.pump(const Duration(milliseconds: 400));
    }

    await doubleTap();
    expect(saved.isSaved('zz-card'), isTrue);
    expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
    await doubleTap();
    expect(saved.isSaved('zz-card'), isFalse);
    expect(find.byIcon(Icons.favorite_rounded), findsNothing);
    await tester.pump(const Duration(seconds: 5));
  });
}
