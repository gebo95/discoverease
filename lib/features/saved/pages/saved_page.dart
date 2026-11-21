import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/listing.dart';
import '../../../repositories/destination_repository.dart';
import '../../../repositories/listing_repository.dart';
import '../../../repositories/saved_repository.dart';
import '../../../shared/components/chips/de_filter_chip.dart';
import '../../../shared/theme/de_colors.dart';
import '../../../shared/theme/de_radius.dart';
import '../../../shared/theme/de_spacing.dart';
import '../../listing/pages/listing_detail_page.dart';
import '../utils/saved_group_builder.dart';

/// Saved experiences, grouped country -> area. Each country shows photo cards
/// only for the areas that contain saves; tapping an area card toggles that
/// area's saved experiences open or closed.
class SavedPage extends StatefulWidget {
  const SavedPage({super.key});

  @override
  State<SavedPage> createState() => _SavedPageState();
}

class _SavedPageState extends State<SavedPage> {
  /// null means "All" categories.
  String? _categoryFilter;

  /// `country/area` key of the expanded area card, or null when none is open.
  String? _selectedAreaKey;

  @override
  Widget build(BuildContext context) {
    final savedItems = context.watch<SavedRepository>().getAllSaved();
    final listingRepository = context.watch<ListingRepository>();
    final destinationRepository = context.watch<DestinationRepository>();
    final groups = SavedGroupBuilder.build(
      saved: savedItems,
      listings: listingRepository,
      destinations: destinationRepository,
    );

    final categories = <String>{
      for (final country in groups)
        for (final area in country.areas)
          for (final category in area.categories) category.name,
    }.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    // A removed save can leave a filter that matches nothing; fall back to All.
    final activeFilter = categories.contains(_categoryFilter)
        ? _categoryFilter
        : null;

    final countries = <_CountryView>[];
    for (final country in groups) {
      final areas = <_AreaView>[];
      for (final area in country.areas) {
        final items = <_SavedItem>[
          for (final category in area.categories)
            if (activeFilter == null || category.name == activeFilter)
              for (final listing in category.listings)
                _SavedItem(listing: listing, category: category.name),
        ];
        if (items.isEmpty) continue;
        areas.add(
          _AreaView(
            key: '${country.name}/${area.name}',
            name: area.name,
            imageUrl: area.imageUrl,
            items: items,
          ),
        );
      }
      if (areas.isNotEmpty) {
        countries.add(_CountryView(name: country.name, areas: areas));
      }
    }

    final totalCount = countries.fold<int>(0, (sum, c) => sum + c.count);

    return Scaffold(
      backgroundColor: DEColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(DESpacing.md),
          children: [
            const SizedBox(height: 12),
            const Text(
              'Saved',
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w900,
                color: DEColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Keep the experiences you want to come back to.',
              style: TextStyle(fontSize: 15, color: DEColors.textSecondary),
            ),
            const SizedBox(height: DESpacing.lg),
            if (groups.isEmpty)
              const _EmptySavedState()
            else ...[
              if (categories.length > 1) ...[
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      DEFilterChip(
                        label: 'All',
                        selected: activeFilter == null,
                        onTap: () => setState(() => _categoryFilter = null),
                      ),
                      for (final category in categories) ...[
                        const SizedBox(width: DESpacing.sm),
                        DEFilterChip(
                          label: category,
                          selected: activeFilter == category,
                          onTap: () =>
                              setState(() => _categoryFilter = category),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: DESpacing.lg),
              ],
              Text(
                'Experiences · $totalCount',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: DEColors.textPrimary,
                ),
              ),
              const SizedBox(height: DESpacing.md),
              for (final country in countries)
                _CountrySection(
                  country: country,
                  selectedAreaKey: _selectedAreaKey,
                  onAreaTap: (key) => setState(() {
                    _selectedAreaKey = _selectedAreaKey == key ? null : key;
                  }),
                  onListingTap: (listing) => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ListingDetailPage(listing: listing),
                    ),
                  ),
                  onRemove: (listing) =>
                      context.read<SavedRepository>().remove(listing.id),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SavedItem {
  final Listing listing;
  final String category;

  const _SavedItem({required this.listing, required this.category});
}

class _AreaView {
  final String key;
  final String name;
  final String imageUrl;
  final List<_SavedItem> items;

  const _AreaView({
    required this.key,
    required this.name,
    required this.imageUrl,
    required this.items,
  });
}

class _CountryView {
  final String name;
  final List<_AreaView> areas;

  const _CountryView({required this.name, required this.areas});

  int get count => areas.fold<int>(0, (sum, area) => sum + area.items.length);
}

class _CountrySection extends StatelessWidget {
  final _CountryView country;
  final String? selectedAreaKey;
  final ValueChanged<String> onAreaTap;
  final ValueChanged<Listing> onListingTap;
  final ValueChanged<Listing> onRemove;

  const _CountrySection({
    required this.country,
    required this.selectedAreaKey,
    required this.onAreaTap,
    required this.onListingTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    _AreaView? selected;
    for (final area in country.areas) {
      if (area.key == selectedAreaKey) selected = area;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: DESpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  country.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: DEColors.textPrimary,
                  ),
                ),
              ),
              Text(
                '${country.count} saved',
                style: const TextStyle(
                  color: DEColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: DESpacing.sm),
          SizedBox(
            height: 150,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: country.areas.length,
              itemBuilder: (context, index) {
                final area = country.areas[index];
                return _SavedAreaCard(
                  key: ValueKey('saved-area:${area.key}'),
                  name: area.name,
                  imageUrl: area.imageUrl,
                  count: area.items.length,
                  selected: area.key == selectedAreaKey,
                  onTap: () => onAreaTap(area.key),
                );
              },
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child: selected == null
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.only(top: DESpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${selected.name} · ${selected.items.length} saved',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: DEColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: DESpacing.sm),
                        for (final item in selected.items)
                          _SavedListingCard(
                            listing: item.listing,
                            category: item.category,
                            onTap: () => onListingTap(item.listing),
                            onRemove: () => onRemove(item.listing),
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

class _SavedAreaCard extends StatelessWidget {
  final String name;
  final String imageUrl;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  const _SavedAreaCard({
    super.key,
    required this.name,
    required this.imageUrl,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(DERadius.large);
    return Semantics(
      button: true,
      selected: selected,
      label: '$name, $count saved',
      child: Container(
        width: 170,
        margin: const EdgeInsets.only(right: DESpacing.md),
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 14,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        foregroundDecoration: BoxDecoration(
          borderRadius: radius,
          border: selected
              ? Border.all(color: DEColors.primary, width: 3)
              : null,
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (imageUrl.isEmpty)
                const ColoredBox(color: DEColors.border)
              else
                Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) =>
                      const ColoredBox(color: DEColors.border),
                ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.68),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(DERadius.pill),
                  ),
                  child: Text(
                    '$count',
                    style: const TextStyle(
                      color: DEColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: DESpacing.md,
                right: DESpacing.md,
                bottom: DESpacing.md,
                child: Row(
                  children: [
                    const Icon(
                      Icons.location_on_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned.fill(
                child: Material(
                  type: MaterialType.transparency,
                  child: InkWell(onTap: onTap),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SavedListingCard extends StatelessWidget {
  final Listing listing;
  final String category;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _SavedListingCard({
    required this.listing,
    required this.category,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: listing.isUnavailable ? 0.6 : 1,
      child: Container(
      margin: const EdgeInsets.only(bottom: DESpacing.md),
      decoration: BoxDecoration(
        color: DEColors.surface,
        borderRadius: BorderRadius.circular(DERadius.extraLarge),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(DERadius.extraLarge),
          child: Padding(
            padding: const EdgeInsets.all(DESpacing.sm),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(DERadius.large),
                  child: Image.network(
                    listing.imageUrl,
                    width: 82,
                    height: 82,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const SizedBox(
                      width: 82,
                      height: 82,
                      child: ColoredBox(
                        color: DEColors.border,
                        child: Icon(Icons.image_not_supported_outlined),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: DESpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        listing.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 4),
                      if (listing.unavailability != null) ...[
                        Text(
                          listing.unavailability!.label,
                          style: const TextStyle(
                            color: DEColors.textSecondary,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        if (listing.unavailability!.message.isNotEmpty)
                          Text(
                            '"${listing.unavailability!.message}"',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: DEColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                      ] else
                        Text(
                          '${listing.location} · ${listing.price}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: DEColors.textSecondary),
                        ),
                      const SizedBox(height: 4),
                      Text(
                        category,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: DEColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Remove from saved',
                  onPressed: onRemove,
                  icon: const Icon(
                    Icons.favorite_rounded,
                    color: Colors.redAccent,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
    );
  }
}

class _EmptySavedState extends StatelessWidget {
  const _EmptySavedState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(DESpacing.lg),
      decoration: BoxDecoration(
        color: DEColors.surface,
        borderRadius: BorderRadius.circular(DERadius.extraLarge),
      ),
      child: const Column(
        children: [
          Icon(Icons.bookmark_border_rounded, size: 40, color: DEColors.primary),
          SizedBox(height: DESpacing.sm),
          Text(
            'No saved experiences yet',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          SizedBox(height: 4),
          Text(
            'Save a place from its detail page and it will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(color: DEColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
