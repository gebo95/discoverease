import 'package:flutter/material.dart';

import '../../../models/listing.dart';
import '../../../shared/components/cards/de_experience_card.dart';
import '../../../shared/components/sections/de_section_header.dart';
import '../../../shared/theme/de_spacing.dart';

class CategoryExperienceSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final String actionText;
  final List<Listing> listings;
  final VoidCallback? onSeeAll;
  final ValueChanged<Listing>? onListingTap;
  final ValueChanged<Listing>? onSaveTap;

  const CategoryExperienceSection({
    super.key,
    required this.title,
    required this.subtitle,
    required this.listings,
    this.actionText = "See All →",
    this.onSeeAll,
    this.onListingTap,
    this.onSaveTap,
  });

  @override
  Widget build(BuildContext context) {
    if (listings.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DESectionHeader(
          title: title,
          subtitle: subtitle,
          actionText: actionText,
          onAction: onSeeAll,
        ),
        SizedBox(
          height: 320,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: listings.length + 1,
            itemBuilder: (context, index) {
              if (index == listings.length) {
                return _SeeAllCard(label: actionText, onTap: onSeeAll);
              }

              final listing = listings[index];

              return DEExperienceCard(
                listing: listing,
                onTap: () {
                  onListingTap?.call(listing);
                },
                onSave: () {
                  onSaveTap?.call(listing);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SeeAllCard extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const _SeeAllCard({required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: 170,
        margin: const EdgeInsets.only(right: DESpacing.md),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(DESpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.arrow_forward_rounded, size: 32),
                const SizedBox(height: DESpacing.sm),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
