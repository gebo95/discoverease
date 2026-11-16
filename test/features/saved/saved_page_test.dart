import 'package:discoverease/features/saved/pages/saved_page.dart';
import 'package:discoverease/models/saved_experience.dart';
import 'package:discoverease/repositories/destination_repository.dart';
import 'package:discoverease/repositories/listing_repository.dart';
import 'package:discoverease/repositories/saved_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  late SavedRepository saved;
  late ListingRepository listings;
  late DestinationRepository destinations;

  setUp(() {
    saved = SavedRepository()
      ..loadAccountData(const [
        SavedExperience(
          id: 'save-tour',
          listingId: 'sunset-cruise',
          destination: 'Bahamas',
        ),
        SavedExperience(
          id: 'save-music',
          listingId: 'sandy-toes-beach-bar',
          destination: 'Bahamas',
        ),
      ]);
    listings = ListingRepository();
    destinations = DestinationRepository();
  });

  tearDown(() {
    saved.dispose();
    listings.dispose();
    destinations.dispose();
  });

  Future<void> pumpPage(WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<SavedRepository>.value(value: saved),
          ChangeNotifierProvider<ListingRepository>.value(value: listings),
          ChangeNotifierProvider<DestinationRepository>.value(
            value: destinations,
          ),
        ],
        child: const MaterialApp(home: SavedPage()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows only areas with saves, collapsed until tapped', (
    tester,
  ) async {
    await pumpPage(tester);

    expect(find.text('Bahamas'), findsOneWidget);
    expect(find.text('Nassau'), findsOneWidget);
    expect(find.text('Paradise Island'), findsOneWidget);
    // Events stay hidden until their area card is tapped.
    expect(find.text('Sunset Cruise'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('saved-area:Bahamas/Paradise Island')));
    await tester.pumpAndSettle();
    expect(find.text('Sunset Cruise'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('saved-area:Bahamas/Paradise Island')));
    await tester.pumpAndSettle();
    expect(find.text('Sunset Cruise'), findsNothing);
  });

  testWidgets('category chips hide areas with no matching saves', (
    tester,
  ) async {
    await pumpPage(tester);

    // The chip row scrolls sideways; bring the chip on screen before tapping.
    await tester.ensureVisible(find.text('Tours'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tours'));
    await tester.pumpAndSettle();

    expect(find.text('Paradise Island'), findsOneWidget);
    expect(find.text('Nassau'), findsNothing);

    await tester.ensureVisible(find.text('All'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('All'));
    await tester.pumpAndSettle();
    expect(find.text('Nassau'), findsOneWidget);
  });
}
