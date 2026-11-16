import 'package:discoverease/shared/components/cards/de_experience_card.dart';
import 'package:discoverease/mock_data/listings/live_now.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('browse experience card content wraps without overflow', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            children: [
              SizedBox(
                height: 340,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [DEExperienceCard(listing: liveNowListings.first)],
                ),
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
