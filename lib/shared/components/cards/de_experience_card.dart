import 'package:flutter/material.dart';

import '../../theme/de_colors.dart';
import '../../theme/de_radius.dart';
import '../../theme/de_spacing.dart';
import '../../../models/listing.dart';

class DEExperienceCard extends StatelessWidget {
  final Listing listing;
  final bool isSaved;
  final VoidCallback? onTap;
  final VoidCallback? onSave;

  const DEExperienceCard({
    super.key,
    required this.listing,
    this.isSaved = false,
    this.onTap,
    this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final ratingLabel = listing.rating?.toStringAsFixed(1) ?? 'New';
    return InkWell(
      borderRadius: BorderRadius.circular(DERadius.extraLarge),
      onTap: onTap,
      child: Container(
        width: 220,
        height: 320,
        margin: const EdgeInsets.only(right: DESpacing.md),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(DERadius.extraLarge),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(DERadius.extraLarge),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Hero(
                tag: "listing-image-${listing.id}",
                child: Image.network(
                  listing.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const ColoredBox(
                      color: DEColors.border,
                      child: Center(
                        child: Icon(
                          Icons.image_not_supported_outlined,
                          color: DEColors.textSecondary,
                        ),
                      ),
                    );
                  },
                ),
              ),

              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.35, 1],
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.88),
                      ],
                    ),
                  ),
                ),
              ),

              Positioned(
                top: 12,
                left: 12,
                right: 12,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (listing.category.isNotEmpty)
                      Expanded(
                        child: Align(
                          alignment: Alignment.topLeft,
                          child: _Badge(
                            label: listing.category,
                            backgroundColor: DEColors.primary,
                          ),
                        ),
                      ),
                    if (listing.category.isNotEmpty)
                      const SizedBox(width: 8)
                    else
                      const Spacer(),
                    Material(
                      color: Colors.black.withValues(alpha: 0.28),
                      shape: const CircleBorder(),
                      child: IconButton(
                        onPressed: onSave,
                        icon: Icon(
                          isSaved
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              if (listing.status.isNotEmpty)
                Positioned(
                  left: 12,
                  bottom: 122,
                  child: _Badge(
                    label: listing.status,
                    backgroundColor: DEColors.success,
                  ),
                ),

              Positioned(
                left: 14,
                right: 14,
                bottom: 14,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      listing.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      listing.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.82),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (listing.rating != null) ...[
                              const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                              const SizedBox(width: 4),
                            ],
                            Text(
                              ratingLabel,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          listing.price,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.88),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.location_on_rounded, color: Colors.white, size: 16),
                            const SizedBox(width: 3),
                            SizedBox(
                              width: 90,
                              child: Text(
                                listing.location,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.82),
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} // closes build method / DEExperienceCard class

class _Badge extends StatelessWidget {
  final String label;
  final Color backgroundColor;

  const _Badge({required this.label, required this.backgroundColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(DERadius.pill),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
