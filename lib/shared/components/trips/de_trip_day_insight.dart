import 'package:flutter/material.dart';

import '../../theme/de_colors.dart';
import '../../theme/de_radius.dart';
import '../../theme/de_spacing.dart';

class DETripDayInsight extends StatelessWidget {
  final int plannedExperiences;
  final int completedExperiences;
  final String dayTitle;

  const DETripDayInsight({
    super.key,
    required this.plannedExperiences,
    required this.completedExperiences,
    required this.dayTitle,
  });

  @override
  Widget build(BuildContext context) {
    final insight = _buildInsight();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: DESpacing.md,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: DEColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(DERadius.large),
        border: Border.all(color: DEColors.primary.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: DEColors.surface,
              shape: BoxShape.circle,
            ),
            child: Icon(insight.icon, color: DEColors.primary, size: 21),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight.title,
                  style: const TextStyle(
                    color: DEColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  insight.message,
                  style: const TextStyle(
                    color: DEColors.textSecondary,
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  _DayInsight _buildInsight() {
    if (plannedExperiences == 0) {
      return _DayInsight(
        icon: Icons.auto_awesome_rounded,
        title: '$dayTitle is wide open',
        message: 'Plenty of free time to explore or simply take it easy.',
      );
    }

    if (completedExperiences == plannedExperiences) {
      return const _DayInsight(
        icon: Icons.celebration_rounded,
        title: 'A day well explored',
        message: 'Everything planned for this day has been completed.',
      );
    }

    final remainingExperiences = plannedExperiences - completedExperiences;

    if (plannedExperiences <= 2) {
      return _DayInsight(
        icon: Icons.spa_rounded,
        title: 'A relaxed day ahead',
        message: _remainingMessage(remainingExperiences),
      );
    }

    if (plannedExperiences <= 4) {
      return _DayInsight(
        icon: Icons.balance_rounded,
        title: 'A balanced day ahead',
        message: _remainingMessage(remainingExperiences),
      );
    }

    return _DayInsight(
      icon: Icons.local_fire_department_rounded,
      title: 'A full day of experiences',
      message: _remainingMessage(remainingExperiences),
    );
  }

  String _remainingMessage(int remaining) {
    if (remaining == 0) {
      return 'Everything planned for this day is complete.';
    }

    if (remaining == 1) {
      return 'You have one experience still waiting for you.';
    }

    return 'You have $remaining experiences still waiting for you.';
  }
}

class _DayInsight {
  final IconData icon;
  final String title;
  final String message;

  const _DayInsight({
    required this.icon,
    required this.title,
    required this.message,
  });
}
