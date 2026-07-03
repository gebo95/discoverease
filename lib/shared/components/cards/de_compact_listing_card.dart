import 'package:flutter/material.dart';

import '../../../models/listing.dart';
import '../../theme/de_colors.dart';
import '../../theme/de_radius.dart';
import '../../theme/de_spacing.dart';

class DECompactListingCard extends StatelessWidget {
  final Listing listing;
  final VoidCallback? onTap;

  const DECompactListingCard({super.key, required this.listing, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 220,
        margin: const EdgeInsets.only(right: DESpacing.md),
        decoration: BoxDecoration(
          color: DEColors.surface,
          borderRadius: BorderRadius.circular(DERadius.large),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(DERadius.large),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.network(
                listing.imageUrl,
                height: 130,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
              Padding(
                padding: const EdgeInsets.all(DESpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      listing.category,
                      style: const TextStyle(
                        fontSize: 12,
                        color: DEColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      listing.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: DEColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "📍 ${listing.location}",
                      style: const TextStyle(
                        fontSize: 13,
                        color: DEColors.textSecondary,
                      ),
                    ),
                    if (listing.pulse != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        "🔴 ${listing.pulse}",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: DEColors.accent,
                        ),
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
