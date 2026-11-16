import 'package:flutter/material.dart';

import '../../theme/de_colors.dart';
import '../../theme/de_radius.dart';
import '../../theme/de_spacing.dart';

class DETripSnapshot extends StatelessWidget {
  final int plannedExperiences;
  final int savedPlaces;
  final double estimatedBudget;
  final int totalDays;

  const DETripSnapshot({
    super.key,
    required this.plannedExperiences,
    required this.savedPlaces,
    required this.estimatedBudget,
    required this.totalDays,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: DESpacing.lg),
      padding: const EdgeInsets.all(DESpacing.md),
      decoration: BoxDecoration(
        color: DEColors.surface,
        borderRadius: BorderRadius.circular(DERadius.extraLarge),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TRIP SNAPSHOT',
            style: TextStyle(
              color: DEColors.primary,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),

          const SizedBox(height: DESpacing.md),

          Row(
            children: [
              Expanded(
                child: _SnapshotItem(
                  icon: Icons.place_rounded,
                  value: "$plannedExperiences",
                  label: "Planned",
                ),
              ),
              Expanded(
                child: _SnapshotItem(
                  icon: Icons.favorite_rounded,
                  value: "$savedPlaces",
                  label: "Saved",
                ),
              ),
            ],
          ),

          const SizedBox(height: DESpacing.md),

          Row(
            children: [
              Expanded(
                child: _SnapshotItem(
                  icon: Icons.payments_rounded,
                  value: _formatCurrency(estimatedBudget),
                  label: "Budget",
                ),
              ),
              Expanded(
                child: _SnapshotItem(
                  icon: Icons.calendar_month_rounded,
                  value: "$totalDays",
                  label: "Days",
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double amount) =>
      '\$${amount.toStringAsFixed(amount == amount.roundToDouble() ? 0 : 2)}';
}

class _SnapshotItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _SnapshotItem({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(4),
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: DEColors.background,
        borderRadius: BorderRadius.circular(DERadius.large),
      ),
      child: Column(
        children: [
          Icon(icon, color: DEColors.primary),

          const SizedBox(height: 10),

          Text(
            value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
          ),

          const SizedBox(height: 2),

          Text(label, style: const TextStyle(color: DEColors.textSecondary)),
        ],
      ),
    );
  }
}
