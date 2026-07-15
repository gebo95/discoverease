import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/listing.dart';
import '../../../repositories/destination_repository.dart';
import '../../../repositories/listing_repository.dart';
import '../../../shared/components/sections/de_section_header.dart';
import '../../../shared/theme/de_colors.dart';
import '../../../shared/theme/de_radius.dart';
import '../../../shared/theme/de_spacing.dart';

class DiscoverThisWeekSection extends StatefulWidget {
  const DiscoverThisWeekSection({super.key});

  @override
  State<DiscoverThisWeekSection> createState() =>
      _DiscoverThisWeekSectionState();
}

class _DiscoverThisWeekSectionState extends State<DiscoverThisWeekSection> {
  final PageController _pageController = PageController(viewportFraction: 0.92);

  Timer? _timer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();

    _timer = Timer.periodic(
      const Duration(seconds: 6),
      (_) => _advanceCarousel(),
    );
  }

  List<Listing> _getCurrentListings() {
    final listingRepository = context.read<ListingRepository>();
    final destinationRepository = context.read<DestinationRepository>();
    final destination = destinationRepository.currentDestination;

    return listingRepository.getForDestination(destination.country);
  }

  void _advanceCarousel() {
    if (!_pageController.hasClients) {
      return;
    }

    final listings = _getCurrentListings();

    if (listings.length <= 1) {
      return;
    }

    final nextPage = (_currentPage + 1) % listings.length;

    _pageController.animateToPage(
      nextPage,
      duration: const Duration(milliseconds: 550),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final destination = context
        .watch<DestinationRepository>()
        .currentDestination;

    final listingRepository = context.read<ListingRepository>();

    final listings = listingRepository.getForDestination(destination.country);

    if (listings.isEmpty) {
      return const SizedBox.shrink();
    }

    if (_currentPage >= listings.length) {
      _currentPage = 0;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_pageController.hasClients) {
          _pageController.jumpToPage(0);
        }
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DESectionHeader(
          title: "✨ Discover This Week",
          subtitle:
              "Handpicked experiences in ${destination.name} worth checking out.",
          actionText: "Explore →",
          onAction: () {
            // Later: open Explore for the current destination.
          },
        ),
        SizedBox(
          height: 340,
          child: PageView.builder(
            controller: _pageController,
            itemCount: listings.length,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemBuilder: (context, index) {
              final listing = listings[index];

              return Padding(
                padding: const EdgeInsets.only(right: DESpacing.sm),
                child: _HeroExperienceCard(
                  listing: listing,
                  badge: _badgeFor(index),
                  onTap: () {
                    // Later: open Listing Detail.
                  },
                ),
              );
            },
          ),
        ),
        const SizedBox(height: DESpacing.md),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(listings.length, (index) {
            final selected = index == _currentPage;

            return AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: selected ? 22 : 7,
              height: 7,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: selected ? DEColors.primary : DEColors.border,
                borderRadius: BorderRadius.circular(DERadius.pill),
              ),
            );
          }),
        ),
      ],
    );
  }

  String _badgeFor(int index) {
    switch (index % 3) {
      case 0:
        return "✨ Handpicked";
      case 1:
        return "🌅 Best This Week";
      default:
        return "🔥 Worth Discovering";
    }
  }
}

class _HeroExperienceCard extends StatelessWidget {
  final Listing listing;
  final String badge;
  final VoidCallback? onTap;

  const _HeroExperienceCard({
    required this.listing,
    required this.badge,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(DERadius.extraLarge),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(DERadius.extraLarge),
          image: DecorationImage(
            image: NetworkImage(listing.imageUrl),
            fit: BoxFit.cover,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 28,
              spreadRadius: -4,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(DERadius.extraLarge),
          child: Container(
            padding: const EdgeInsets.all(DESpacing.lg),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.35, 1],
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.64),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.topLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: DEColors.primary,
                      borderRadius: BorderRadius.circular(DERadius.pill),
                    ),
                    child: Text(
                      badge,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  listing.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  listing.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.84),
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      color: Colors.amber,
                      size: 19,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      listing.rating.toStringAsFixed(1),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    const Icon(
                      Icons.location_on_rounded,
                      color: Colors.white,
                      size: 17,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        listing.location,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.84),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
