import 'package:flutter/material.dart';

import '../../../models/trip_section.dart';
import '../pickers/de_day_picker.dart';
import '../pickers/de_time_section_picker.dart';
import '../../theme/de_colors.dart';
import '../../theme/de_radius.dart';
import '../../theme/de_spacing.dart';

void showDEPlanExperienceSheet(
  BuildContext context, {
  required String experienceTitle,
  required List<String> days,
  required void Function(int dayIndex, TripSection section) onPlan,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => DEPlanExperienceSheet(
      experienceTitle: experienceTitle,
      days: days,
      onPlan: onPlan,
    ),
  );
}

class DEPlanExperienceSheet extends StatefulWidget {
  final String experienceTitle;
  final List<String> days;
  final void Function(int dayIndex, TripSection section) onPlan;

  const DEPlanExperienceSheet({
    super.key,
    required this.experienceTitle,
    required this.days,
    required this.onPlan,
  });

  @override
  State<DEPlanExperienceSheet> createState() => _DEPlanExperienceSheetState();
}

class _DEPlanExperienceSheetState extends State<DEPlanExperienceSheet> {
  int selectedDay = 0;
  TripSection? selectedSection;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(DESpacing.lg),
      decoration: const BoxDecoration(
        color: DEColors.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(DERadius.extraLarge),
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: DEColors.border,
                    borderRadius: BorderRadius.circular(DERadius.pill),
                  ),
                ),
              ),

              const SizedBox(height: DESpacing.lg),

              Text(
                widget.experienceTitle,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                "When would you like to enjoy this?",
                style: TextStyle(color: DEColors.textSecondary),
              ),

              const SizedBox(height: DESpacing.xl),

              const Text(
                "Choose a day",
                style: TextStyle(fontWeight: FontWeight.w700),
              ),

              const SizedBox(height: DESpacing.sm),

              DEDayPicker(
                days: widget.days,
                selectedIndex: selectedDay,
                onSelected: (index) {
                  setState(() {
                    selectedDay = index;
                  });
                },
              ),

              const SizedBox(height: DESpacing.xl),

              const Text(
                "Choose a time",
                style: TextStyle(fontWeight: FontWeight.w700),
              ),

              const SizedBox(height: DESpacing.sm),

              DETimeSectionPicker(
                selectedSection: selectedSection,
                onSelected: (section) {
                  setState(() {
                    selectedSection = section;
                  });
                },
              ),

              const SizedBox(height: DESpacing.xl),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: selectedSection == null
                      ? null
                      : () {
                          Navigator.pop(context);

                          widget.onPlan(selectedDay, selectedSection!);
                        },
                  child: const Text("Plan Experience"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
