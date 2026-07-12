import 'package:flutter/material.dart';

import '../../../repositories/listing_repository.dart';
import '../../../shared/components/cards/de_experience_card.dart';
import 'package:provider/provider.dart';
import '../../../shared/components/sections/de_section_header.dart';

class LiveNowSection extends StatelessWidget {
  const LiveNowSection({super.key});

  @override
  Widget build(BuildContext context) {
    final listingRepository = context.read<ListingRepository>();
    final listings = listingRepository.getLiveNow();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DESectionHeader(
          title: "🔴 Live Right Now",
          subtitle: "Experiences happening around you.",
          actionText: "Explore →",
          onAction: () {
            // Later this will open Explore with Live filter selected.
          },
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 320,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: listings.length,
            itemBuilder: (context, index) {
              final listing = listings[index];

              return DEExperienceCard(
                title: listing.title,
                subtitle: listing.subtitle,
                location: listing.location,
                imageUrl: listing.imageUrl,
                rating: listing.rating,
                price: listing.price,
                badge: listing.category,
                status: listing.status,
                isSaved: false,
                onTap: () {
                  // Add your existing listing-detail navigation here later.
                },
                onSave: () {
                  // Connect this to the Save flow later.
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
