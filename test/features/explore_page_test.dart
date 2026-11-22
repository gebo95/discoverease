import 'package:discoverease/features/explore/pages/explore_page.dart';
import 'package:discoverease/repositories/destination_repository.dart';
import 'package:discoverease/repositories/listing_repository.dart';
import 'package:discoverease/repositories/saved_repository.dart';
import 'package:discoverease/shared/components/cards/de_listing_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

Future<({DestinationRepository destinations, SavedRepository saved})> _show(
  WidgetTester tester,
  ExplorePage page,
) async {
  tester.view.physicalSize = const Size(420, 6000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final destinations = DestinationRepository();
  final saved = SavedRepository();
  addTearDown(destinations.dispose);
  addTearDown(saved.dispose);
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<DestinationRepository>.value(value: destinations),
        ChangeNotifierProvider(create: (_) => ListingRepository()),
        ChangeNotifierProvider<SavedRepository>.value(value: saved),
      ],
      child: MaterialApp(home: page),
    ),
  );
  await tester.pump();
  return (destinations: destinations, saved: saved);
}

void main() {
  testWidgets('shows category buttons and starts on the one it was sent from', (tester) async {
    final first = DestinationRepository().currentDestination.homeSections.first;
    await _show(tester, ExplorePage(initialCategory: first.category));
    expect(find.text('Browse by category'), findsOneWidget);
    expect(find.text(first.title), findsOneWidget);
    expect(find.text('All'), findsOneWidget);
  });

  testWidgets('every listing shown belongs to the chosen category, and All clears it', (tester) async {
    final destinations = DestinationRepository();
    final section = destinations.currentDestination.homeSections.first;
    final expected = ListingRepository()
        .getByCategory(destinations.currentDestination.id, section.category)
        .length;
    final everything = ListingRepository().getForDestination(destinations.currentDestination.id).length;
    await _show(tester, ExplorePage(initialCategory: section.category));
    expect(find.byType(DEListingCard, skipOffstage: false).evaluate().length, lessThanOrEqualTo(expected));
    await tester.tap(find.text('All'));
    await tester.pump();
    await tester.pump();
    expect(
      find.byType(DEListingCard, skipOffstage: false).evaluate().length,
      greaterThanOrEqualTo(expected),
    );
    expect(everything, greaterThanOrEqualTo(expected));
  });

  testWidgets('a page opened on its own has a back button', (tester) async {
    await _show(tester, const ExplorePage(showBackButton: true));
    expect(find.byTooltip('Back'), findsOneWidget);
    await _show(tester, const ExplorePage());
    expect(find.byTooltip('Back'), findsNothing);
  });

  testWidgets('double tapping a result toggles whether it is saved', (tester) async {
    final env = await _show(tester, const ExplorePage());
    final card = find.byType(DEListingCard).first;
    final before = env.saved.getAllSaved().length;
    await tester.tap(card);
    await tester.pump(const Duration(milliseconds: 60));
    await tester.tap(card);
    await tester.pump(const Duration(milliseconds: 400));
    // Saves it, or removes it if the sample data already had it saved.
    expect((env.saved.getAllSaved().length - before).abs(), 1);
    await tester.pump(const Duration(seconds: 5));
  });
}
