import 'package:flutter/material.dart';

import '../../../models/trip_section.dart';
import '../../theme/de_colors.dart';
import '../../theme/de_radius.dart';
import '../../theme/de_spacing.dart';

class DETimeSectionPicker extends StatelessWidget {
  final TripSection? selectedSection;
  final ValueChanged<TripSection> onSelected;

  const DETimeSectionPicker({
    super.key,
    required this.selectedSection,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SectionCard(
            emoji: "☀️",
            title: "Morning",
            selected: selectedSection == TripSection.morning,
            onTap: () => onSelected(TripSection.morning),
          ),
        ),

        const SizedBox(width: DESpacing.md),

        Expanded(
          child: _SectionCard(
            emoji: "🌤",
            title: "Afternoon",
            selected: selectedSection == TripSection.afternoon,
            onTap: () => onSelected(TripSection.afternoon),
          ),
        ),

        const SizedBox(width: DESpacing.md),

        Expanded(
          child: _SectionCard(
            emoji: "🌅",
            title: "Evening",
            selected: selectedSection == TripSection.evening,
            onTap: () => onSelected(TripSection.evening),
          ),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String emoji;
  final String title;
  final bool selected;
  final VoidCallback onTap;

  const _SectionCard({
    required this.emoji,
    required this.title,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(DERadius.large),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: DESpacing.lg),
        decoration: BoxDecoration(
          color: selected
              ? DEColors.primary.withValues(alpha: 0.08)
              : DEColors.surface,
          borderRadius: BorderRadius.circular(DERadius.large),
          border: Border.all(
            color: selected ? DEColors.primary : DEColors.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),

            const SizedBox(height: DESpacing.sm),

            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: selected ? DEColors.primary : DEColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
