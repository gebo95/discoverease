import 'package:flutter/material.dart';

import '../../theme/de_colors.dart';
import '../../theme/de_radius.dart';
import '../../theme/de_spacing.dart';
import '../../../models/review.dart';

class DETravelerTipCard extends StatelessWidget {
  final Review review;

  const DETravelerTipCard({super.key, required this.review});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DESpacing.md),
      decoration: BoxDecoration(
        color: DEColors.surface,
        borderRadius: BorderRadius.circular(DERadius.extraLarge),
        border: Border.all(color: DEColors.border.withValues(alpha: 0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            review.title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: DEColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '"${review.comment}"',
            style: const TextStyle(
              fontSize: 15,
              height: 1.45,
              color: DEColors.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: DEColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(DERadius.large),
              border: Border.all(
                color: DEColors.primary.withValues(alpha: 0.14),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "💡 DiscoverEase Tip",
                  style: TextStyle(
                    color: DEColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  review.tip,
                  style: const TextStyle(
                    color: DEColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              ...List.generate(
                5,
                (index) => Icon(
                  index < review.rating.round()
                      ? Icons.star_rounded
                      : Icons.star_border_rounded,
                  size: 17,
                  color: Colors.amber,
                ),
              ),
              const Spacer(),
              Text(
                review.author,
                style: const TextStyle(
                  color: DEColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
