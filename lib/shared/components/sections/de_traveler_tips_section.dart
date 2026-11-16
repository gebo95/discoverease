import 'package:flutter/material.dart';

import '../../../models/review.dart';
import '../../theme/de_colors.dart';
import '../../theme/de_radius.dart';
import '../../theme/de_spacing.dart';
import '../cards/de_traveler_tip_card.dart';

class DETravelerTipsSection extends StatelessWidget {
  final List<Review> reviews;
  final int reviewCount;
  final VoidCallback? onViewAll;

  const DETravelerTipsSection({
    super.key,
    required this.reviews,
    required this.reviewCount,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    final visibleReviews = reviews.take(2).toList();

    if (visibleReviews.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DESpacing.md),
      decoration: BoxDecoration(
        color: DEColors.surface,
        borderRadius: BorderRadius.circular(DERadius.extraLarge),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "💬 Traveler Tips",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          const Text(
            "Advice from people who’ve already been here.",
            style: TextStyle(color: DEColors.textSecondary),
          ),
          const SizedBox(height: DESpacing.md),
          ...visibleReviews.map(
            (review) => Padding(
              padding: const EdgeInsets.only(bottom: DESpacing.md),
              child: DETravelerTipCard(review: review),
            ),
          ),
          InkWell(
            onTap: onViewAll,
            borderRadius: BorderRadius.circular(DERadius.large),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: DESpacing.sm),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      "View all $reviewCount traveler tips",
                      style: const TextStyle(
                        color: DEColors.primary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    size: 18,
                    color: DEColors.primary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
