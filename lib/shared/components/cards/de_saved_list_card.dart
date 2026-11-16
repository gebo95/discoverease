import 'package:flutter/material.dart';

import '../../theme/de_colors.dart';
import '../../theme/de_radius.dart';
import '../../theme/de_spacing.dart';

class DESavedListCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String icon;
  final String? imageUrl;
  final VoidCallback? onTap;

  const DESavedListCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.imageUrl,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: DESpacing.md),
        padding: const EdgeInsets.all(DESpacing.md),
        decoration: BoxDecoration(
          color: DEColors.surface,
          borderRadius: BorderRadius.circular(DERadius.extraLarge),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: DEColors.background,
                borderRadius: BorderRadius.circular(DERadius.large),
                image: imageUrl == null
                    ? null
                    : DecorationImage(
                        image: NetworkImage(imageUrl!),
                        fit: BoxFit.cover,
                      ),
              ),
              child: imageUrl == null
                  ? Center(
                      child: Text(icon, style: const TextStyle(fontSize: 26)),
                    )
                  : null,
            ),
            const SizedBox(width: DESpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "$icon $title",
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: DEColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
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
            const Icon(
              Icons.chevron_right_rounded,
              color: DEColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
