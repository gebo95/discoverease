import 'package:flutter/material.dart';

import '../../../repositories/listing_repository.dart';
import '../../../shared/components/cards/de_listing_card.dart';
import '../../../shared/components/inputs/de_search_bar.dart';
import '../../../shared/theme/de_colors.dart';
import '../../../shared/theme/de_spacing.dart';
import 'package:provider/provider.dart';
import '../../../shared/components/chips/de_filter_chip.dart';
import '../../../repositories/destination_repository.dart';

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  String? selectedFilter;

  String searchQuery = "";

  @override
  Widget build(BuildContext context) {
    final destination = context
        .watch<DestinationRepository>()
        .currentDestination;

    final listingRepository = context.read<ListingRepository>();

    final listings = listingRepository.searchListings(
      destination.country,
      searchQuery,
      filter: selectedFilter,
    );

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

            DESearchBar(
              hintText: "Search places, food, tours...",
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
            ),

            const SizedBox(height: 22),

            const Text(
              "What are you in the mood for?",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),

            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _buildFilterChip("❤️ Romantic"),
                _buildFilterChip("🍽 Hungry"),
                _buildFilterChip("🎵 Live Music"),
                _buildFilterChip("🏖 Beach"),
                _buildFilterChip("👨‍👩‍👧 Family"),
                _buildFilterChip("✨ Hidden Gems"),
                _buildFilterChip("🌅 Sunset"),
                _buildFilterChip("💰 Budget"),
              ],
            ),
            const SizedBox(height: 28),

            const Text(
              "Recommended Experiences",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),

            const SizedBox(height: 16),

            if (listings.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Column(
                  children: [
                    const Icon(
                      Icons.search_off_rounded,
                      size: 46,
                      color: DEColors.textSecondary,
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      "No experiences found",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      "Try another search or choose a different mood.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: DEColors.textSecondary),
                    ),
                    if (selectedFilter != null)
                      TextButton(
                        onPressed: () {
                          setState(() {
                            selectedFilter = null;
                          });
                        },
                        child: const Text("Clear filter"),
                      ),
                  ],
                ),
              )
            else
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

  Widget _buildFilterChip(String label) {
    return DEFilterChip(
      label: label,
      selected: selectedFilter == label,
      onTap: () {
        setState(() {
          selectedFilter = selectedFilter == label ? null : label;
        });
      },
    );
  }
}
