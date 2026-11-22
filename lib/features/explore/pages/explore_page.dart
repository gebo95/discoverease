import 'package:flutter/material.dart';

import '../../../shared/navigation/de_page_route.dart';
import '../../../repositories/listing_repository.dart';
import '../../../repositories/featured_repository.dart';
import '../../../shared/components/cards/de_listing_card.dart';
import '../../../shared/components/inputs/de_search_bar.dart';
import '../../../shared/theme/de_colors.dart';
import '../../../shared/theme/de_spacing.dart';
import 'package:provider/provider.dart';
import '../../../shared/components/chips/de_filter_chip.dart';
import '../../../repositories/saved_repository.dart';
import '../../../shared/utils/saved_toggle.dart';
import '../../listing/pages/listing_detail_page.dart';
import '../../../repositories/destination_repository.dart';

class ExplorePage extends StatefulWidget {
  final String? initialFilter;

  /// A category to start on, such as the row "See all" was tapped from.
  final String? initialCategory;
  final String? initialAreaId;
  final String? initialDestinationId;
  final bool showBackButton;

  const ExplorePage({
    super.key,
    this.initialFilter,
    this.initialCategory,
    this.initialAreaId,
    this.initialDestinationId,
    this.showBackButton = false,
  });

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  String? selectedFilter;
  String? selectedCategory;
  String? selectedAreaId;
  String? _lastDestinationId;
  String? _destinationOverride;

  String searchQuery = "";

  @override
  void initState() {
    super.initState();
    selectedFilter = widget.initialFilter;
    selectedCategory = widget.initialCategory;
    selectedAreaId = widget.initialAreaId;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final destinationId =
        context.read<DestinationRepository>().currentDestination.id;
    if (_lastDestinationId == null && widget.initialDestinationId != null) {
      final requestedDestination = context
          .read<DestinationRepository>()
          .getById(widget.initialDestinationId!);
      _destinationOverride = requestedDestination?.id;
    }
    if (_lastDestinationId != null && _lastDestinationId != destinationId) {
      selectedAreaId = null;
    }
    _lastDestinationId = destinationId;
  }

  @override
  Widget build(BuildContext context) {
    final destinationRepository = context.watch<DestinationRepository>();
    final destination = _destinationOverride == null
        ? destinationRepository.currentDestination
        : destinationRepository.getById(_destinationOverride!) ??
              destinationRepository.currentDestination;
    final areas = destinationRepository.getAreasForDestination(destination.id);
    final effectiveAreaId = areas.any((area) => area.id == selectedAreaId)
        ? selectedAreaId
        : null;

    final listingRepository = context.watch<ListingRepository>();

    final found = listingRepository.searchListings(
      destination.id,
      searchQuery,
      filter: selectedFilter,
      areaId: effectiveAreaId,
      category: selectedCategory,
    );
    // Paid Featured placements come first; everything else keeps its order.
    final featured = context.watch<FeaturedRepository?>();
    final listings =
        featured?.featuredFirst(found, (listing) => listing.id) ?? found;
    final saved = context.watch<SavedRepository?>();

    // Category buttons come from the destination's own home rows, so "See all"
    // on a row lands on the matching button.
    final categoryChoices = <({String label, String value})>[
      for (final section in destination.homeSections)
        (label: section.title, value: section.category),
    ];
    if (selectedCategory != null &&
        !categoryChoices.any((choice) => choice.value == selectedCategory)) {
      categoryChoices.insert(0, (label: selectedCategory!, value: selectedCategory!));
    }

    return Scaffold(
      backgroundColor: DEColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(DESpacing.md),
          children: [
            const SizedBox(height: 12),

            if (widget.showBackButton)
              Row(
                children: [
                  IconButton(
                    tooltip: 'Back',
                    onPressed: () => Navigator.maybePop(context),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  const SizedBox(width: 4),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Explore',
                          style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            color: DEColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Find the right experience for today.',
                          style: TextStyle(fontSize: 15, color: DEColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            else ...[
              const Text(
                'Explore',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  color: DEColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Find the right experience for today.',
                style: TextStyle(fontSize: 15, color: DEColors.textSecondary),
              ),
            ],

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

            if (categoryChoices.isNotEmpty) ...[
              const Text(
                'Browse by category',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: DEFilterChip(
                        label: 'All',
                        selected: selectedCategory == null,
                        onTap: () => setState(() => selectedCategory = null),
                      ),
                    ),
                    for (final choice in categoryChoices)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: DEFilterChip(
                          label: choice.label,
                          selected: selectedCategory == choice.value,
                          onTap: () => setState(
                            () => selectedCategory = selectedCategory == choice.value
                                ? null
                                : choice.value,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
            ],

            if (areas.isNotEmpty) ...[
              const Text(
                'Explore by area',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: DEFilterChip(
                        label: 'All areas',
                        selected: effectiveAreaId == null,
                        onTap: () => setState(() => selectedAreaId = null),
                      ),
                    ),
                    ...areas.map(
                      (area) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: DEFilterChip(
                          label: area.name,
                          selected: effectiveAreaId == area.id,
                          onTap: () => setState(() {
                            selectedAreaId = area.id;
                          }),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
            ],
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
                    Text(
                      effectiveAreaId == null
                          ? "Try another search or choose a different mood."
                          : "There are no listed experiences in this area that match those filters.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: DEColors.textSecondary),
                    ),
                    if (selectedCategory != null)
                      TextButton(
                        onPressed: () => setState(() => selectedCategory = null),
                        child: const Text("Clear category"),
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
                    if (effectiveAreaId != null)
                      TextButton(
                        onPressed: () {
                          setState(() {
                            selectedAreaId = null;
                          });
                        },
                        child: const Text("Clear area"),
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
                  listingId: listing.id,
                  isSaved: saved?.isSaved(listing.id) ?? false,
                  onToggleSaved: () => toggleSavedListing(context, listing),
                  onTap: () {
                    Navigator.push(
                      context,
                      dePageRoute(page: ListingDetailPage(listing: listing)),
                    );
                  },
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
