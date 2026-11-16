import 'package:flutter/material.dart';

import '../../theme/de_colors.dart';
import '../../theme/de_spacing.dart';
import '../cards/de_trip_experience_card.dart';

class DEDaySection extends StatelessWidget {
  final String title;
  final List<DETripExperienceCard> experiences;
  final VoidCallback? onPlanExperience;

  const DEDaySection({
    super.key,
    required this.title,
    this.experiences = const [],
    this.onPlanExperience,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: DESpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: DEColors.textPrimary,
            ),
          ),

          const SizedBox(height: DESpacing.md),

          if (experiences.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(DESpacing.lg),
              decoration: BoxDecoration(
                color: DEColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: DEColors.border),
              ),
              child: Column(
                children: [
                  const Text(
                    "Nothing planned yet",
                    style: TextStyle(color: DEColors.textSecondary),
                  ),
                  const SizedBox(height: DESpacing.md),
                  ElevatedButton(
                    onPressed: onPlanExperience,
                    child: const Text("Plan Experience"),
                  ),
                ],
              ),
            )
          else ...[
            ...experiences,
            const SizedBox(height: DESpacing.sm),
            TextButton.icon(
              onPressed: onPlanExperience,
              icon: const Icon(Icons.add),
              label: const Text("Plan Experience"),
            ),
          ],
        ],
      ),
    );
  }
}
