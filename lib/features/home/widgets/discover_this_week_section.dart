import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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

  void _advanceCarousel() {
    if (!_pageController.hasClients) {
      return;
    }

    final listingRepository = context.read<ListingRepository>();
    final listings = listingRepository.getLiveNow();

    if (listings.isEmpty) {
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
    final listingRepository = context.read<ListingRepository>();
    final listings = listingRepository.getLiveNow();

    if (listings.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DESectionHeader(
          title: "✨ Discover This Week",
          subtitle: "Handpicked experiences worth checking out.",
          actionText: "Explore →",
          onAction: () {
            // Later: open Explore with featured results.
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
                  title: listing.title,
                  subtitle: listing.subtitle,
                  location: listing.location,
                  imageUrl: listing.imageUrl,
                  rating: listing.rating,
                  price: listing.price,
                  badge: index == 0
                      ? "✨ Handpicked"
                      : index == 1
                      ? "🌅 Best at Sunset"
                      : "🔥 Worth Discovering",
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
}

class _HeroExperienceCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String location;
  final String imageUrl;
  final double rating;
  final String price;
  final String badge;
  final VoidCallback? onTap;

  const _HeroExperienceCard({
    required this.title,
    required this.subtitle,
    required this.location,
    required this.imageUrl,
    required this.rating,
    required this.price,
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
            image: NetworkImage(imageUrl),
            fit: BoxFit.cover,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.14),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Container(
          padding: const EdgeInsets.all(DESpacing.lg),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(DERadius.extraLarge),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: const [0.35, 1],
              colors: [
                Colors.transparent,
                Colors.black.withValues(alpha: 0.72),
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
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  height: 1.05,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                subtitle,
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
                  const Icon(Icons.star_rounded, color: Colors.amber, size: 19),
                  const SizedBox(width: 4),
                  Text(
                    rating.toStringAsFixed(1),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    price,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
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
                      location,
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
    );
  }
}
