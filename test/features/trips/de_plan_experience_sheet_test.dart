import 'package:discoverease/shared/components/bottom_sheets/de_plan_experience_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('saved experience planning opens on the selected trip day', (
    tester,
  ) async {
    var plannedDay = -1;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () => showDEPlanExperienceSheet(
                  context,
                  experienceTitle: 'Saved tour',
                  days: const ['Day 1', 'Day 2'],
                  initialDayIndex: 1,
                  onPlan: (
                    dayIndex,
                    section, {
                    time,
                    closingTime,
                    travelMinutes,
                    reservation,
                    estimatedCost,
                    notes,
                  }) {
                    plannedDay = dayIndex;
                  },
                ),
                child: const Text('Open planner'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open planner'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Morning'));
    await tester.ensureVisible(find.text('Plan Experience'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Plan Experience'));
    await tester.pumpAndSettle();

    expect(plannedDay, 1);
  });
}
