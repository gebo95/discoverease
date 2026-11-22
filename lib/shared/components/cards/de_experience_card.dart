import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../theme/de_colors.dart';
import '../../theme/de_radius.dart';
import '../../theme/de_spacing.dart';
import '../../../models/listing.dart';
import '../../../repositories/business_pulse_repository.dart';
import '../../../repositories/saved_repository.dart';
import '../../utils/card_labels.dart';
import '../../utils/saved_toggle.dart';
import '../badges/de_pulse_badge.dart';

class DEExperienceCard extends StatelessWidget {
  final Listing listing;
  final bool isSaved;
  final VoidCallback? onTap;
  final VoidCallback? onSave;

  /// The category the row holding this card is already named after, so the
  /// card does not repeat it.
  final String? sectionCategory;

  const DEExperienceCard({
    super.key,
    required this.listing,
    this.isSaved = false,
    this.onTap,
    this.onSave,
    this.sectionCategory,
  });

  void _toggleSaved(BuildContext context) {
    // A parent that handles saving itself takes over.
    if (onSave != null) {
      onSave!();
      return;
    }
    toggleSavedListing(context, listing);
  }

  @override
  Widget build(BuildContext context) {
    final rating = listing.rating;
    // Nullable so the card also works where these are not set up (tests).
    final pulses = context.watch<BusinessPulseRepository?>();
    final pulse = pulses?.forListing(listing.id);
    final saved =
        isSaved ||
        (context.watch<SavedRepository?>()?.isSaved(listing.id) ?? false);
    final labels = cardLabels(
      category: listing.category,
      subcategory: listing.subcategory,
      sectionCategory: sectionCategory,
    );
    return InkWell(
      borderRadius: BorderRadius.circular(DERadius.extraLarge),
      onTap: onTap,
      // Double tap saves the place (the heart then shows); again to remove it.
      onDoubleTap: () => _toggleSaved(context),
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
              // No Hero here: the same listing can appear in several home
              // sections at once, and two Heroes with one tag break navigation.
              Image.network(
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

              if (labels.isNotEmpty || saved)
                Positioned(
                  top: 12,
                  left: 12,
                  right: 12,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Align(
                          alignment: Alignment.topLeft,
                          child: labels.isEmpty
                              ? const SizedBox.shrink()
                              : _CyclingBadge(
                                  labels: labels,
                                  backgroundColor: DEColors.primary,
                                ),
                        ),
                      ),
                      // The heart only appears once the place is saved.
                      if (saved)
                        Material(
                          color: Colors.black.withValues(alpha: 0.28),
                          shape: const CircleBorder(),
                          child: IconButton(
                            onPressed: () => _toggleSaved(context),
                            icon: const Icon(
                              Icons.favorite_rounded,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

              // One highlight above the title: a live Pulse if there is one,
              // otherwise the listing's own status ("New", "Ends Dec 3").
              if (pulse != null)
                Positioned(
                  left: 12,
                  bottom: 122,
                  right: 12,
                  child: Align(
                    alignment: Alignment.bottomLeft,
                    child: DEPulseBadge(
                      label: pulse.tag,
                      animate: !(pulses?.isSeen(pulse) ?? true),
                    ),
                  ),
                )
              else if (listing.status.isNotEmpty)
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
                        // Only once there is a real rating; until then nothing.
                        if (rating != null)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                              const SizedBox(width: 4),
                              Text(
                                rating.toStringAsFixed(1),
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

  const _Badge({super.key, required this.label, required this.backgroundColor});

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


/// The category label. When a listing has several (its category and types), it
/// slowly switches between them.
class _CyclingBadge extends StatefulWidget {
  const _CyclingBadge({required this.labels, required this.backgroundColor});

  final List<String> labels;
  final Color backgroundColor;

  @override
  State<_CyclingBadge> createState() => _CyclingBadgeState();
}

class _CyclingBadgeState extends State<_CyclingBadge> {
  Timer? _timer;
  int _index = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _timer?.cancel();
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (widget.labels.length > 1 && !still) {
      _timer = Timer.periodic(const Duration(seconds: 3), (_) {
        if (mounted) setState(() => _index++);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.labels[_index % widget.labels.length];
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      child: _Badge(
        key: ValueKey(label),
        label: label,
        backgroundColor: widget.backgroundColor,
      ),
    );
  }
}
