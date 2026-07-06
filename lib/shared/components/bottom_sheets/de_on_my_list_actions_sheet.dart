import 'package:flutter/material.dart';

import '../../theme/de_colors.dart';
import '../../theme/de_radius.dart';
import '../../theme/de_spacing.dart';

void showDEOnMyListActionsSheet(
  BuildContext context, {
  required String title,
  VoidCallback? onViewListing,
  VoidCallback? onPlanExperience,
  VoidCallback? onRemove,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => DEOnMyListActionsSheet(
      title: title,
      onViewListing: onViewListing,
      onPlanExperience: onPlanExperience,
      onRemove: onRemove,
    ),
  );
}

class DEOnMyListActionsSheet extends StatelessWidget {
  final String title;
  final VoidCallback? onViewListing;
  final VoidCallback? onPlanExperience;
  final VoidCallback? onRemove;

  const DEOnMyListActionsSheet({
    super.key,
    required this.title,
    this.onViewListing,
    this.onPlanExperience,
    this.onRemove,
  });

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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: DEColors.border,
                borderRadius: BorderRadius.circular(DERadius.pill),
              ),
            ),
            const SizedBox(height: DESpacing.lg),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(height: DESpacing.md),
            _ActionRow(
              icon: Icons.place_rounded,
              title: "View Listing",
              subtitle: "See photos, details, and reviews",
              onTap: onViewListing,
            ),
            _ActionRow(
              icon: Icons.wb_sunny_rounded,
              title: "Plan Experience",
              subtitle: "Add this to your itinerary",
              onTap: onPlanExperience,
            ),
            _ActionRow(
              icon: Icons.delete_outline_rounded,
              title: "Remove from List",
              subtitle: "Keep your list organized",
              onTap: onRemove,
              isDestructive: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool isDestructive;

  const _ActionRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? Colors.red : DEColors.textPrimary;

    return InkWell(
      borderRadius: BorderRadius.circular(DERadius.large),
      onTap: () {
        Navigator.pop(context);
        onTap?.call();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: DESpacing.md),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: DESpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontWeight: FontWeight.w800, color: color),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: DEColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
