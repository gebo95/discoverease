import 'package:flutter/material.dart';

import '../../../repositories/listing_repository.dart';
import '../../../shared/components/cards/de_experience_card.dart';
import 'package:provider/provider.dart';
import '../../../shared/components/sections/de_section_header.dart';
import '../../../repositories/destination_repository.dart';

class LiveNowSection extends StatelessWidget {
  const LiveNowSection({super.key});

  @override
  Widget build(BuildContext context) {
    final destination = context
        .watch<DestinationRepository>()
        .currentDestination;

    final listingRepository = context.read<ListingRepository>();

    final listings = listingRepository.getLiveNow(destination.country);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DESectionHeader(
          title: "🔴 Live Right Now",
          subtitle: "Happening now in ${destination.name}.",
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

              return DEExperienceCard(listing: listing);
            },
          ),
        ),
      ],
    );
  }
}
