import 'package:discoverease/models/trip.dart';
import 'package:discoverease/shared/components/trips/de_trip_hero.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('trip hero fits a long title and its date range', (tester) async {
    tester.view.physicalSize = const Size(600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              DETripHero(
                trip: Trip(
                  id: 'hero-test',
                  title: 'A Long Family Adventure Across The Islands',
                  destination: 'Bahamas',
                  startDate: DateTime(2027, 6, 1),
                  endDate: DateTime(2027, 6, 8),
                ),
                imageUrl: '',
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
