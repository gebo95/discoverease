import 'package:flutter/material.dart';

import '../../../repositories/listing_repository.dart';
import '../../../shared/components/cards/de_compact_listing_card.dart';

class LiveNowSection extends StatelessWidget {
  const LiveNowSection({super.key});

  @override
  Widget build(BuildContext context) {
    const listingRepository = ListingRepository();
    final listings = listingRepository.getLiveNow();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "🔥 Live Now",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Text("View All", style: TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 270,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: listings.length,
            itemBuilder: (context, index) {
              return DECompactListingCard(listing: listings[index]);
            },
          ),
        ),
      ],
    );
  }
}
