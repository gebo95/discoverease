import 'package:flutter/material.dart';

import '../../theme/de_colors.dart';
import '../../theme/de_radius.dart';
import '../../theme/de_spacing.dart';
import '../../theme/de_text_styles.dart';

class DEListingCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String category;
  final String location;
  final String imageUrl;
  final double rating;
  final String price;
  final String status;
  final String? pulse;
  final VoidCallback? onTap;
  final VoidCallback? onPinTap;

  const DEListingCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.category,
    required this.location,
    required this.imageUrl,
    required this.rating,
    required this.price,
    required this.status,
    this.pulse,
    this.onTap,
    this.onPinTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: DESpacing.lg),
        decoration: BoxDecoration(
          color: DEColors.surface,
          borderRadius: BorderRadius.circular(DERadius.extraLarge),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(DERadius.extraLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Image.network(imageUrl, fit: BoxFit.cover),
                  ),

                  Positioned(
                    top: DESpacing.md,
                    left: DESpacing.md,
                    child: _CircleIconButton(
                      icon: Icons.push_pin_outlined,
                      onTap: onPinTap,
                    ),
                  ),

                  Positioned(
                    top: DESpacing.md,
                    right: DESpacing.md,
                    child: _StatusBadge(status: status),
                  ),
                ],
              ),

              Padding(
                padding: const EdgeInsets.all(DESpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(category, style: DETextStyles.caption),

                    const SizedBox(height: DESpacing.xs),

                    Text(
                      title,
                      style: DETextStyles.heading3,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: DESpacing.xs),

                    Text(
                      subtitle,
                      style: DETextStyles.caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: DESpacing.sm),

                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 18,
                          color: Colors.amber,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          rating.toStringAsFixed(1),
                          style: DETextStyles.caption,
                        ),
                        const SizedBox(width: DESpacing.md),
                        Text(price, style: DETextStyles.caption),
                        const SizedBox(width: DESpacing.md),
                        const Icon(
                          Icons.location_on_outlined,
                          size: 16,
                          color: DEColors.textSecondary,
                        ),
                        const SizedBox(width: 2),
                        Text(location, style: DETextStyles.caption),
                      ],
                    ),

                    if (pulse != null && pulse!.isNotEmpty) ...[
                      const SizedBox(height: DESpacing.sm),
                      Text(
                        "🔴 $pulse",
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: DEColors.accent,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _CircleIconButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.9),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: 20, color: DEColors.textPrimary),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DESpacing.sm,
        vertical: DESpacing.xs,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(DERadius.pill),
      ),
      child: Text(
        status,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: DEColors.success,
        ),
      ),
    );
  }
}
