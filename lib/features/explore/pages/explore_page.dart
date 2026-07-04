import 'package:flutter/material.dart';

import '../../../mock_data/live_now.dart';
import '../../../shared/components/cards/de_listing_card.dart';
import '../../../shared/components/inputs/de_search_bar.dart';
import '../../../shared/theme/de_colors.dart';
import '../../../shared/theme/de_spacing.dart';

class ExplorePage extends StatelessWidget {
  const ExplorePage({super.key});

  @override
  Widget build(BuildContext context) {
    final listings = liveNowListings;

    return Scaffold(
      backgroundColor: DEColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(DESpacing.md),
          children: [
            const SizedBox(height: 12),

            const Text(
              "Explore",
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w900,
                color: DEColors.textPrimary,
              ),
            ),

            const SizedBox(height: 6),

            const Text(
              "Find the right experience for today.",
              style: TextStyle(fontSize: 15, color: DEColors.textSecondary),
            ),

            const SizedBox(height: 20),

            const DESearchBar(hintText: "Search food, tours, beaches..."),

            const SizedBox(height: 22),

            const Text(
              "What are you in the mood for?",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),

            const SizedBox(height: 14),

            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: const [
                _ExploreChip(label: "❤️ Romantic"),
                _ExploreChip(label: "🍽 Hungry"),
                _ExploreChip(label: "🎵 Live Music"),
                _ExploreChip(label: "🏖 Beach"),
                _ExploreChip(label: "👨‍👩‍👧 Family"),
                _ExploreChip(label: "✨ Hidden Gems"),
                _ExploreChip(label: "🌅 Sunset"),
                _ExploreChip(label: "💰 Budget"),
              ],
            ),

            const SizedBox(height: 28),

            const Text(
              "Recommended Experiences",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),

            const SizedBox(height: 16),

            ...listings.map(
              (listing) => DEListingCard(
                title: listing.title,
                subtitle: listing.subtitle,
                category: listing.category,
                location: listing.location,
                imageUrl: listing.imageUrl,
                rating: listing.rating,
                price: listing.price,
                status: listing.status,
                pulse: listing.pulse,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExploreChip extends StatelessWidget {
  final String label;

  const _ExploreChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: DEColors.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: DEColors.border),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          color: DEColors.textPrimary,
        ),
      ),
    );
  }
}
